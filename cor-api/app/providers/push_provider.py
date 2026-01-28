from __future__ import annotations
"""Push notification provider with FCM support."""

import asyncio
import json
import random
import time
from dataclasses import dataclass
from typing import Any

from app.core.config import settings
from app.core.logging import get_logger
from app.providers.base import BaseProvider, ProviderResult

logger = get_logger(__name__)

# FCM error codes that indicate invalid/expired tokens
INVALID_TOKEN_ERRORS = {
    "UNREGISTERED",
    "INVALID_ARGUMENT",
    "NOT_FOUND",
    "registration-token-not-registered",
    "invalid-registration-token",
    "invalid-argument",
}

# FCM error codes that indicate temporary failures (retry possible)
TEMPORARY_ERROR_CODES = {
    "UNAVAILABLE",
    "INTERNAL",
    "QUOTA_EXCEEDED",
    "unavailable",
    "internal-error",
}


@dataclass
class PushNotification:
    """Push notification data."""

    device_token: str
    title: str
    body: str
    data: dict[str, Any] | None = None
    platform: str = "android"  # "android" or "ios"


@dataclass
class PushResult:
    """Result of a push notification send."""

    device_token: str
    success: bool
    provider_status: str  # "sent", "failed", "invalid_token", "expired_token"
    error_message: str | None = None
    message_id: str | None = None


class PushProvider(BaseProvider):
    """
    Provider for push notifications via Firebase Cloud Messaging (FCM).

    When configured with FCM credentials, sends real push notifications.
    Otherwise, simulates push sending with realistic behavior.

    To configure:
    - Set FCM_CREDENTIALS_PATH to path of Firebase service account JSON
    - Or set FCM_CREDENTIALS_JSON with the JSON content as string
    """

    def __init__(self):
        super().__init__(
            name="push",
            base_url=None,  # FCM uses its own SDK
            api_key=None,
        )
        self._sent_count = 0
        self._failed_count = 0
        self._invalid_token_count = 0
        self._fcm_app: Any = None
        self._fcm_initialized = False

    @property
    def is_configured(self) -> bool:
        """Check if FCM credentials are configured."""
        return bool(
            settings.fcm_credentials_path or settings.fcm_credentials_json
        )

    @property
    def is_mock(self) -> bool:
        """Check if provider is using mock data."""
        return not self.is_configured

    def _initialize_fcm(self) -> bool:
        """
        Initialize Firebase Admin SDK.

        Returns:
            True if initialization successful, False otherwise
        """
        if self._fcm_initialized:
            return self._fcm_app is not None

        try:
            import firebase_admin
            from firebase_admin import credentials

            # Check if already initialized
            try:
                self._fcm_app = firebase_admin.get_app()
                self._fcm_initialized = True
                logger.info("FCM: Using existing Firebase app")
                return True
            except ValueError:
                pass  # No app exists, need to initialize

            cred = None

            # Try credentials from JSON string first
            if settings.fcm_credentials_json:
                try:
                    cred_dict = json.loads(settings.fcm_credentials_json)
                    cred = credentials.Certificate(cred_dict)
                    logger.info("FCM: Initialized from JSON string")
                except json.JSONDecodeError as e:
                    logger.error(f"FCM: Failed to parse credentials JSON: {e}")
                    return False

            # Try credentials from file path
            elif settings.fcm_credentials_path:
                try:
                    cred = credentials.Certificate(settings.fcm_credentials_path)
                    logger.info(
                        f"FCM: Initialized from file: {settings.fcm_credentials_path}"
                    )
                except Exception as e:
                    logger.error(f"FCM: Failed to load credentials file: {e}")
                    return False

            if cred is None:
                logger.warning("FCM: No credentials configured")
                return False

            # Initialize the app
            options = {}
            if settings.fcm_project_id:
                options["projectId"] = settings.fcm_project_id

            self._fcm_app = firebase_admin.initialize_app(cred, options)
            self._fcm_initialized = True
            logger.info("FCM: Firebase Admin SDK initialized successfully")
            return True

        except ImportError:
            logger.error("FCM: firebase-admin package not installed")
            return False
        except Exception as e:
            logger.error(f"FCM: Initialization failed: {e}")
            return False

    async def send_notification(
        self,
        notification: PushNotification,
    ) -> PushResult:
        """
        Send a single push notification.

        Args:
            notification: PushNotification with device token, title, body

        Returns:
            PushResult with send status
        """
        start_time = time.perf_counter()

        if self.is_mock:
            result = self._mock_send(notification)
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)
            return result

        # Initialize FCM if needed
        if not self._initialize_fcm():
            self._failed_count += 1
            self.metrics.record_error("FCM not initialized")
            return PushResult(
                device_token=notification.device_token,
                success=False,
                provider_status="failed",
                error_message="FCM not initialized - check credentials",
            )

        # Send via FCM
        result = await self._send_fcm(notification)
        latency_ms = (time.perf_counter() - start_time) * 1000

        if result.success:
            self.metrics.record_success(latency_ms)
        else:
            self.metrics.record_error(result.error_message or "Unknown error")

        return result

    async def _send_fcm(self, notification: PushNotification) -> PushResult:
        """
        Send notification via FCM.

        Args:
            notification: PushNotification to send

        Returns:
            PushResult with send status
        """
        try:
            from firebase_admin import messaging

            # Build the message
            message = self._build_fcm_message(notification)

            # Send (run in executor to not block event loop)
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: messaging.send(message, dry_run=settings.fcm_dry_run),
            )

            self._sent_count += 1
            logger.debug(
                f"FCM: Sent to {notification.device_token[:20]}... "
                f"message_id={response}"
            )

            return PushResult(
                device_token=notification.device_token,
                success=True,
                provider_status="sent",
                message_id=response,
            )

        except Exception as e:
            return self._handle_fcm_error(notification.device_token, e)

    def _build_fcm_message(self, notification: PushNotification) -> Any:
        """
        Build FCM message from notification.

        Args:
            notification: PushNotification data

        Returns:
            firebase_admin.messaging.Message
        """
        from firebase_admin import messaging

        # Build notification payload
        fcm_notification = messaging.Notification(
            title=notification.title,
            body=notification.body,
        )

        # Platform-specific configuration
        android_config = messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                icon="ic_notification",
                color="#FF6B35",  # COR brand color
                channel_id="alerts",
                priority="high",
            ),
        )

        # iOS/APNs configuration (for future use when tokens are available)
        apns_config = messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    alert=messaging.ApsAlert(
                        title=notification.title,
                        body=notification.body,
                    ),
                    sound="default",
                    badge=1,
                    content_available=True,
                ),
            ),
        )

        # Data payload (always strings)
        data = None
        if notification.data:
            data = {k: str(v) for k, v in notification.data.items()}

        return messaging.Message(
            notification=fcm_notification,
            android=android_config,
            apns=apns_config,
            data=data,
            token=notification.device_token,
        )

    def _handle_fcm_error(self, device_token: str, error: Exception) -> PushResult:
        """
        Handle FCM send error and map to appropriate status.

        Args:
            device_token: The device token that failed
            error: The exception raised

        Returns:
            PushResult with appropriate status
        """
        error_str = str(error)
        error_code = getattr(error, "code", None) or ""

        # Check for invalid token errors
        is_invalid_token = any(
            code in error_str or code in error_code
            for code in INVALID_TOKEN_ERRORS
        )

        if is_invalid_token:
            self._failed_count += 1
            self._invalid_token_count += 1
            logger.warning(
                f"FCM: Invalid token {device_token[:20]}... - {error_str}"
            )
            return PushResult(
                device_token=device_token,
                success=False,
                provider_status="invalid_token",
                error_message=f"Token invalid or expired: {error_str}",
            )

        # Check for temporary errors
        is_temporary = any(
            code in error_str or code in error_code
            for code in TEMPORARY_ERROR_CODES
        )

        if is_temporary:
            self._failed_count += 1
            logger.warning(
                f"FCM: Temporary error for {device_token[:20]}... - {error_str}"
            )
            return PushResult(
                device_token=device_token,
                success=False,
                provider_status="failed",
                error_message=f"Temporary error (retry possible): {error_str}",
            )

        # Unknown error
        self._failed_count += 1
        logger.error(f"FCM: Unknown error for {device_token[:20]}... - {error_str}")
        return PushResult(
            device_token=device_token,
            success=False,
            provider_status="failed",
            error_message=error_str,
        )

    async def send_batch(
        self,
        notifications: list[PushNotification],
        batch_size: int | None = None,
    ) -> list[PushResult]:
        """
        Send multiple push notifications in batches.

        Uses FCM's send_each for efficient batch sending.

        Args:
            notifications: List of notifications to send
            batch_size: Number of notifications per batch (max 500 for FCM)

        Returns:
            List of PushResults
        """
        if not notifications:
            return []

        # Use configured batch size, capped at FCM limit of 500
        effective_batch_size = min(
            batch_size or settings.push_batch_size,
            500,  # FCM limit
        )

        results: list[PushResult] = []

        if self.is_mock:
            # Mock mode: send individually
            for i in range(0, len(notifications), effective_batch_size):
                batch = notifications[i: i + effective_batch_size]
                for notification in batch:
                    result = self._mock_send(notification)
                    results.append(result)

                if i + effective_batch_size < len(notifications):
                    await self._batch_delay()

            logger.info(
                f"Batch send complete (mock): {len(results)} notifications, "
                f"{sum(1 for r in results if r.success)} successful"
            )
            return results

        # Real FCM batch sending
        if not self._initialize_fcm():
            # Return all as failed if FCM not initialized
            return [
                PushResult(
                    device_token=n.device_token,
                    success=False,
                    provider_status="failed",
                    error_message="FCM not initialized",
                )
                for n in notifications
            ]

        for i in range(0, len(notifications), effective_batch_size):
            batch = notifications[i: i + effective_batch_size]
            batch_results = await self._send_fcm_batch(batch)
            results.extend(batch_results)

            if i + effective_batch_size < len(notifications):
                await self._batch_delay()

        logger.info(
            f"Batch send complete: {len(results)} notifications, "
            f"{sum(1 for r in results if r.success)} successful, "
            f"{sum(1 for r in results if r.provider_status == 'invalid_token')} invalid tokens"
        )

        return results

    async def _send_fcm_batch(
        self,
        notifications: list[PushNotification],
    ) -> list[PushResult]:
        """
        Send a batch of notifications via FCM send_each.

        Args:
            notifications: List of notifications to send

        Returns:
            List of PushResults
        """
        try:
            from firebase_admin import messaging

            # Build messages
            messages = [self._build_fcm_message(n) for n in notifications]

            # Send batch (run in executor)
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: messaging.send_each(messages, dry_run=settings.fcm_dry_run),
            )

            # Process results
            results: list[PushResult] = []
            for notification, send_response in zip(notifications, response.responses):
                if send_response.success:
                    self._sent_count += 1
                    results.append(
                        PushResult(
                            device_token=notification.device_token,
                            success=True,
                            provider_status="sent",
                            message_id=send_response.message_id,
                        )
                    )
                else:
                    result = self._handle_fcm_error(
                        notification.device_token,
                        send_response.exception,
                    )
                    results.append(result)

            logger.debug(
                f"FCM batch: {response.success_count} sent, "
                f"{response.failure_count} failed"
            )

            return results

        except Exception as e:
            logger.error(f"FCM batch send failed: {e}")
            # Return all as failed
            return [
                PushResult(
                    device_token=n.device_token,
                    success=False,
                    provider_status="failed",
                    error_message=f"Batch send error: {e}",
                )
                for n in notifications
            ]

    async def _batch_delay(self) -> None:
        """Delay between batches to avoid overwhelming FCM."""
        delay_seconds = settings.push_batch_delay_ms / 1000.0
        await asyncio.sleep(delay_seconds)

    def _mock_send(self, notification: PushNotification) -> PushResult:
        """
        Mock push notification sending.

        Simulates realistic behavior:
        - 95% success rate
        - 3% invalid token
        - 2% temporary failure
        """
        # Simulate some processing time
        time.sleep(random.uniform(0.001, 0.01))

        # Simulate different outcomes
        rand = random.random()

        if rand < 0.95:
            # Success
            self._sent_count += 1
            logger.debug(
                f"Mock push sent to {notification.device_token[:20]}... "
                f"({notification.platform})"
            )
            return PushResult(
                device_token=notification.device_token,
                success=True,
                provider_status="sent",
                message_id=f"mock_{int(time.time() * 1000)}",
            )

        elif rand < 0.98:
            # Invalid token (device unregistered)
            self._failed_count += 1
            self._invalid_token_count += 1
            logger.debug(
                f"Mock push failed - invalid token: {notification.device_token[:20]}..."
            )
            return PushResult(
                device_token=notification.device_token,
                success=False,
                provider_status="invalid_token",
                error_message="Device token is no longer valid",
            )

        else:
            # Temporary failure
            self._failed_count += 1
            logger.debug(
                f"Mock push failed - temporary: {notification.device_token[:20]}..."
            )
            return PushResult(
                device_token=notification.device_token,
                success=False,
                provider_status="failed",
                error_message="Temporary provider failure",
            )

    async def fetch(self, **kwargs: Any) -> ProviderResult[Any]:
        """Not used for push provider."""
        raise NotImplementedError("Use send_notification or send_batch instead")

    async def health_check(self) -> bool:
        """
        Check if FCM is properly configured and initialized.

        Returns:
            True if FCM is ready, False otherwise
        """
        if self.is_mock:
            return True  # Mock mode always healthy

        return self._initialize_fcm()

    def get_stats(self) -> dict[str, int]:
        """Get send statistics."""
        return {
            "sent_count": self._sent_count,
            "failed_count": self._failed_count,
            "invalid_token_count": self._invalid_token_count,
        }

    def reset_stats(self) -> None:
        """Reset statistics."""
        self._sent_count = 0
        self._failed_count = 0
        self._invalid_token_count = 0
