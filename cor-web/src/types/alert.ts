export type AlertSeverity = 'info' | 'alert' | 'emergency'
export type AlertStatus = 'draft' | 'sent' | 'canceled'

export interface AlertArea {
  type: 'Feature'
  geometry: {
    type: 'Polygon' | 'MultiPolygon'
    coordinates: number[][][] | number[][][][]
  }
  properties?: Record<string, unknown>
}

export interface CircleArea {
  center: [number, number] // [lat, lon]
  radius_km: number
}

export interface Alert {
  id: string
  title: string
  body: string
  severity: AlertSeverity
  status: AlertStatus
  broadcast: boolean
  neighborhoods: string[] | null
  expires_at: string | null
  sent_at: string | null
  created_at: string
  updated_at: string
  areas?: AlertArea[]
}

export interface AlertCreate {
  title: string
  body: string
  severity: AlertSeverity
  broadcast?: boolean
  neighborhoods?: string[]
  expires_at?: string
  areas?: AlertArea[]
  circles?: CircleArea[]
}

export interface AlertListResponse {
  alerts: Alert[]
  total: number
  page: number
  page_size: number
}

export interface AlertSendResponse {
  message: string
  alert_id: string
  targeted_devices: number
  task_id?: string
}
