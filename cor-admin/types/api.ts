// Admin User Types
export type AdminRole = 'admin' | 'comunicacao' | 'viewer'

export interface AdminUser {
  id: string
  email: string
  name: string
  role: AdminRole
  is_active: boolean
  created_at: string
  updated_at: string
  last_login_at: string | null
}

export interface TokenResponse {
  access_token: string
  token_type: string
  expires_in: number
  user: AdminUser
}

// Operational Status Types
export interface OperationalStatus {
  city_stage: number
  heat_level: number
  updated_at: string
  updated_by: string | null
  is_stale: boolean
}

export interface OperationalStatusUpdate {
  city_stage: number
  heat_level: number
  reason: string
  source: 'manual' | 'alerta_rio' | 'cor' | 'sistema'
}

export interface OperationalStatusHistory {
  id: number
  city_stage: number
  heat_level: number
  reason: string | null
  source: string | null
  changed_at: string
  changed_by: string | null
  ip_address: string | null
}

// Alert Types
export type AlertSeverity = 'info' | 'alert' | 'emergency'
export type AlertStatus = 'draft' | 'sent' | 'canceled'

export interface Alert {
  id: string
  title: string
  body: string
  severity: AlertSeverity
  status: AlertStatus
  is_broadcast: boolean
  target_center_lat: number | null
  target_center_lng: number | null
  target_radius: number | null
  target_polygon: number[][] | null
  sent_at: string | null
  created_at: string
  updated_at: string
  created_by: string | null
  sent_by: string | null
}

export interface AlertCreate {
  title: string
  body: string
  severity: AlertSeverity
  is_broadcast: boolean
  target_center_lat?: number
  target_center_lng?: number
  target_radius?: number
  target_polygon?: number[][]
}

export interface AlertStats {
  alert_id: string
  total_sent: number
  total_delivered: number
  total_opened: number
  total_failed: number
}

// Audit Log Types
export interface AuditLogEntry {
  id: number
  user_id: string | null
  user_email: string | null
  user_name: string | null
  action: string
  resource: string
  resource_id: string | null
  payload_summary: Record<string, unknown> | null
  ip_address: string | null
  user_agent: string | null
  created_at: string
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean
  timestamp: string
  data: T
  cache?: {
    stale: boolean
    age_seconds: number | null
    cached_at: string | null
  }
}

export interface PaginatedResponse<T> {
  success: boolean
  timestamp: string
  data: T[]
  total: number
}

// Alert Send Response
export interface AlertSendResponse {
  success: boolean
  data: Alert
  devices_targeted: number
  task_id: string | null
}
