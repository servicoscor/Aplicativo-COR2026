"""Tests for PushProvider with FCM mocking."""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from dataclasses import dataclass

from app.providers.push_provider import (
    PushProvider,
    PushNotification,
    PushResult,
    INVALID_TOKEN_ERRORS,
    TEMPORARY_ERROR_CODES,
)


class TestPushProviderMock:
    """Tests for PushProvider in mock mode (no FCM configured)."""

    @pytest.mark.asyncio
    async def test_is_mock_when_not_configured(self) -> None:
        """Test provider is in mock mode when FCM not configured."""
        provider = PushProvider()

        assert provider.is_mock is True
        assert provider.is_configured is False

        await provider.close()

    @pytest.mark.asyncio
    async def test_send_notification_mock_mode(self) -> None:
        """Test send_notification returns mock result when not configured."""
        provider = PushProvider()

        notification = PushNotification(
            device_token="test_token_12345",
            title="Test Alert",
            body="This is a test notification",
            platform="android",
        )

        result = await provider.send_notification(notification)

        assert isinstance(result, PushResult)
        assert result.device_token == "test_token_12345"
        # Mock has 95% success rate, so just check it returns a valid result
        assert result.provider_status in ["sent", "failed", "invalid_token"]

        await provider.close()

    @pytest.mark.asyncio
    async def test_send_batch_mock_mode(self) -> None:
        """Test send_batch returns mock results when not configured."""
        provider = PushProvider()

        notifications = [
            PushNotification(
                device_token=f"token_{i}",
                title="Test Alert",
                body="Test body",
            )
            for i in range(10)
        ]

        results = await provider.send_batch(notifications, batch_size=5)

        assert len(results) == 10
        assert all(isinstance(r, PushResult) for r in results)

        await provider.close()

    @pytest.mark.asyncio
    async def test_send_batch_empty(self) -> None:
        """Test send_batch with empty list."""
        provider = PushProvider()

        results = await provider.send_batch([])

        assert results == []

        await provider.close()

    @pytest.mark.asyncio
    async def test_health_check_mock_mode(self) -> None:
        """Test health check returns True in mock mode."""
        provider = PushProvider()

        result = await provider.health_check()

        assert result is True

        await provider.close()

    @pytest.mark.asyncio
    async def test_stats_tracking_mock_mode(self) -> None:
        """Test statistics are tracked in mock mode."""
        provider = PushProvider()
        provider.reset_stats()

        notifications = [
            PushNotification(
                device_token=f"token_{i}",
                title="Test",
                body="Test",
            )
            for i in range(100)  # Send enough to get statistical distribution
        ]

        await provider.send_batch(notifications)

        stats = provider.get_stats()
        assert stats["sent_count"] >= 0
        assert stats["failed_count"] >= 0
        assert stats["invalid_token_count"] >= 0
        assert stats["sent_count"] + stats["failed_count"] == 100

        await provider.close()


class TestPushProviderConfiguration:
    """Tests for PushProvider configuration."""

    def test_is_configured_with_credentials_path(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test provider is configured when FCM_CREDENTIALS_PATH is set."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/creds.json",
        )
        provider = PushProvider()

        assert provider.is_configured is True
        assert provider.is_mock is False

    def test_is_configured_with_credentials_json(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test provider is configured when FCM_CREDENTIALS_JSON is set."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            None,
        )
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_json",
            '{"type": "service_account", "project_id": "test"}',
        )
        provider = PushProvider()

        assert provider.is_configured is True
        assert provider.is_mock is False


class TestPushProviderFCMIntegration:
    """Tests for PushProvider FCM integration using method patching."""

    @pytest.mark.asyncio
    async def test_send_notification_fcm_success(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test successful FCM notification send."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/credentials.json",
        )

        provider = PushProvider()

        # Mock the _send_fcm method directly
        async def mock_send_fcm(notification):
            return PushResult(
                device_token=notification.device_token,
                success=True,
                provider_status="sent",
                message_id="projects/test/messages/12345",
            )

        provider._send_fcm = mock_send_fcm
        provider._initialize_fcm = lambda: True

        notification = PushNotification(
            device_token="fcm_token_12345",
            title="Emergency Alert",
            body="Severe weather warning",
            data={"alert_id": "123", "severity": "emergency"},
            platform="android",
        )

        result = await provider.send_notification(notification)

        assert result.success is True
        assert result.provider_status == "sent"
        assert result.message_id == "projects/test/messages/12345"
        assert result.device_token == "fcm_token_12345"

        await provider.close()

    @pytest.mark.asyncio
    async def test_send_notification_fcm_invalid_token(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test FCM send with invalid token error."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/credentials.json",
        )

        provider = PushProvider()

        # Mock _send_fcm to simulate invalid token
        async def mock_send_fcm(notification):
            return PushResult(
                device_token=notification.device_token,
                success=False,
                provider_status="invalid_token",
                error_message="Token invalid or expired: UNREGISTERED",
            )

        provider._send_fcm = mock_send_fcm
        provider._initialize_fcm = lambda: True

        notification = PushNotification(
            device_token="invalid_token",
            title="Test",
            body="Test",
        )

        result = await provider.send_notification(notification)

        assert result.success is False
        assert result.provider_status == "invalid_token"
        assert "invalid" in result.error_message.lower() or "expired" in result.error_message.lower()

        await provider.close()

    @pytest.mark.asyncio
    async def test_send_notification_fcm_temporary_error(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test FCM send with temporary error."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/credentials.json",
        )

        provider = PushProvider()

        # Mock _send_fcm to simulate temporary error
        async def mock_send_fcm(notification):
            return PushResult(
                device_token=notification.device_token,
                success=False,
                provider_status="failed",
                error_message="Temporary error (retry possible): UNAVAILABLE",
            )

        provider._send_fcm = mock_send_fcm
        provider._initialize_fcm = lambda: True

        notification = PushNotification(
            device_token="valid_token",
            title="Test",
            body="Test",
        )

        result = await provider.send_notification(notification)

        assert result.success is False
        assert result.provider_status == "failed"
        assert "retry" in result.error_message.lower() or "temporary" in result.error_message.lower()

        await provider.close()

    @pytest.mark.asyncio
    async def test_send_notification_fcm_init_failure(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test FCM send when initialization fails."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/credentials.json",
        )

        provider = PushProvider()
        provider._initialize_fcm = lambda: False

        notification = PushNotification(
            device_token="some_token",
            title="Test",
            body="Test",
        )

        result = await provider.send_notification(notification)

        assert result.success is False
        assert result.provider_status == "failed"
        assert "not initialized" in result.error_message.lower()

        await provider.close()

    @pytest.mark.asyncio
    async def test_send_batch_fcm_success(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test successful FCM batch send."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/credentials.json",
        )
        monkeypatch.setattr(
            "app.core.config.settings.push_batch_size",
            500,
        )
        monkeypatch.setattr(
            "app.core.config.settings.push_batch_delay_ms",
            10,
        )

        provider = PushProvider()
        provider._initialize_fcm = lambda: True

        # Mock _send_fcm_batch
        async def mock_send_fcm_batch(notifications):
            return [
                PushResult(
                    device_token=n.device_token,
                    success=True,
                    provider_status="sent",
                    message_id=f"msg_{i}",
                )
                for i, n in enumerate(notifications)
            ]

        provider._send_fcm_batch = mock_send_fcm_batch

        notifications = [
            PushNotification(
                device_token=f"token_{i}",
                title="Batch Test",
                body="Test body",
            )
            for i in range(5)
        ]

        results = await provider.send_batch(notifications)

        assert len(results) == 5
        assert all(r.success for r in results)
        assert all(r.provider_status == "sent" for r in results)

        await provider.close()

    @pytest.mark.asyncio
    async def test_send_batch_fcm_mixed_results(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test FCM batch send with mixed success/failure."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/credentials.json",
        )
        monkeypatch.setattr(
            "app.core.config.settings.push_batch_size",
            500,
        )
        monkeypatch.setattr(
            "app.core.config.settings.push_batch_delay_ms",
            10,
        )

        provider = PushProvider()
        provider._initialize_fcm = lambda: True

        # Mock _send_fcm_batch with mixed results
        async def mock_send_fcm_batch(notifications):
            results = []
            for i, n in enumerate(notifications):
                if i in [2, 4]:  # Indices 2 and 4 fail
                    results.append(
                        PushResult(
                            device_token=n.device_token,
                            success=False,
                            provider_status="invalid_token",
                            error_message="Invalid token",
                        )
                    )
                else:
                    results.append(
                        PushResult(
                            device_token=n.device_token,
                            success=True,
                            provider_status="sent",
                            message_id=f"msg_{i}",
                        )
                    )
            return results

        provider._send_fcm_batch = mock_send_fcm_batch

        notifications = [
            PushNotification(
                device_token=f"token_{i}",
                title="Mixed Test",
                body="Test body",
            )
            for i in range(5)
        ]

        results = await provider.send_batch(notifications)

        assert len(results) == 5

        successes = sum(1 for r in results if r.success)
        failures = sum(1 for r in results if not r.success)
        invalid_tokens = sum(1 for r in results if r.provider_status == "invalid_token")

        assert successes == 3
        assert failures == 2
        assert invalid_tokens == 2

        await provider.close()

    @pytest.mark.asyncio
    async def test_batch_size_limit(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test that batch size is capped at FCM limit of 500."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/credentials.json",
        )
        monkeypatch.setattr(
            "app.core.config.settings.push_batch_size",
            500,
        )
        monkeypatch.setattr(
            "app.core.config.settings.push_batch_delay_ms",
            1,
        )

        provider = PushProvider()
        provider._initialize_fcm = lambda: True

        call_counts = []

        async def mock_send_fcm_batch(notifications):
            call_counts.append(len(notifications))
            return [
                PushResult(
                    device_token=n.device_token,
                    success=True,
                    provider_status="sent",
                    message_id=f"msg_{i}",
                )
                for i, n in enumerate(notifications)
            ]

        provider._send_fcm_batch = mock_send_fcm_batch

        # Send more than 500 notifications
        notifications = [
            PushNotification(
                device_token=f"token_{i}",
                title="Large Batch",
                body="Test",
            )
            for i in range(750)
        ]

        results = await provider.send_batch(notifications, batch_size=500)

        assert len(results) == 750
        # Should be split into batches of max 500
        assert len(call_counts) == 2
        assert call_counts[0] == 500
        assert call_counts[1] == 250

        await provider.close()


class TestPushProviderErrorCodes:
    """Tests for error code handling."""

    def test_invalid_token_error_codes(self) -> None:
        """Test that invalid token error codes are recognized."""
        assert "UNREGISTERED" in INVALID_TOKEN_ERRORS
        assert "INVALID_ARGUMENT" in INVALID_TOKEN_ERRORS
        assert "NOT_FOUND" in INVALID_TOKEN_ERRORS
        assert "registration-token-not-registered" in INVALID_TOKEN_ERRORS

    def test_temporary_error_codes(self) -> None:
        """Test that temporary error codes are recognized."""
        assert "UNAVAILABLE" in TEMPORARY_ERROR_CODES
        assert "INTERNAL" in TEMPORARY_ERROR_CODES
        assert "QUOTA_EXCEEDED" in TEMPORARY_ERROR_CODES

    def test_handle_fcm_error_invalid_token(self) -> None:
        """Test error handling maps invalid token correctly."""
        provider = PushProvider()

        error = Exception("The registration token is not registered")
        error.code = "UNREGISTERED"

        result = provider._handle_fcm_error("test_token", error)

        assert result.success is False
        assert result.provider_status == "invalid_token"
        assert result.device_token == "test_token"

    def test_handle_fcm_error_temporary(self) -> None:
        """Test error handling maps temporary error correctly."""
        provider = PushProvider()

        error = Exception("Service temporarily unavailable")
        error.code = "UNAVAILABLE"

        result = provider._handle_fcm_error("test_token", error)

        assert result.success is False
        assert result.provider_status == "failed"
        assert "retry" in result.error_message.lower() or "temporary" in result.error_message.lower()

    def test_handle_fcm_error_unknown(self) -> None:
        """Test error handling for unknown errors."""
        provider = PushProvider()

        error = Exception("Some unknown error occurred")
        error.code = "UNKNOWN_CODE"

        result = provider._handle_fcm_error("test_token", error)

        assert result.success is False
        assert result.provider_status == "failed"


class TestPushNotificationDataclass:
    """Tests for PushNotification dataclass."""

    def test_default_platform(self) -> None:
        """Test default platform is android."""
        notification = PushNotification(
            device_token="token",
            title="Title",
            body="Body",
        )

        assert notification.platform == "android"

    def test_with_data_payload(self) -> None:
        """Test notification with data payload."""
        notification = PushNotification(
            device_token="token",
            title="Alert",
            body="Emergency",
            data={"alert_id": "123", "type": "weather"},
        )

        assert notification.data["alert_id"] == "123"
        assert notification.data["type"] == "weather"

    def test_with_empty_data(self) -> None:
        """Test notification with empty data dict."""
        notification = PushNotification(
            device_token="token",
            title="Title",
            body="Body",
            data={},
        )

        assert notification.data == {}

    def test_without_data(self) -> None:
        """Test notification without data field."""
        notification = PushNotification(
            device_token="token",
            title="Title",
            body="Body",
        )

        assert notification.data is None


class TestPushResultDataclass:
    """Tests for PushResult dataclass."""

    def test_success_result(self) -> None:
        """Test successful result."""
        result = PushResult(
            device_token="token",
            success=True,
            provider_status="sent",
            message_id="msg_12345",
        )

        assert result.success is True
        assert result.provider_status == "sent"
        assert result.message_id == "msg_12345"
        assert result.error_message is None

    def test_failure_result(self) -> None:
        """Test failure result."""
        result = PushResult(
            device_token="token",
            success=False,
            provider_status="invalid_token",
            error_message="Token expired",
        )

        assert result.success is False
        assert result.provider_status == "invalid_token"
        assert result.error_message == "Token expired"
        assert result.message_id is None


class TestPushProviderHealthCheck:
    """Tests for health check functionality."""

    @pytest.mark.asyncio
    async def test_health_check_mock_returns_true(self) -> None:
        """Test health check returns True in mock mode."""
        provider = PushProvider()
        assert provider.is_mock is True

        result = await provider.health_check()
        assert result is True

        await provider.close()

    @pytest.mark.asyncio
    async def test_health_check_configured_init_success(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test health check initializes FCM when configured."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/creds.json",
        )

        provider = PushProvider()
        provider._initialize_fcm = lambda: True

        assert provider.is_mock is False

        result = await provider.health_check()
        assert result is True

        await provider.close()

    @pytest.mark.asyncio
    async def test_health_check_configured_init_failure(
        self,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test health check returns False when FCM init fails."""
        monkeypatch.setattr(
            "app.core.config.settings.fcm_credentials_path",
            "/path/to/creds.json",
        )

        provider = PushProvider()
        provider._initialize_fcm = lambda: False

        result = await provider.health_check()
        assert result is False

        await provider.close()
