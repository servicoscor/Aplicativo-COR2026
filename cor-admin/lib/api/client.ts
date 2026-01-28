import axios, { AxiosInstance, AxiosError } from 'axios'
import type {
  AdminUser,
  Alert,
  AlertCreate,
  AlertSendResponse,
  AlertStats,
  ApiResponse,
  AuditLogEntry,
  OperationalStatus,
  OperationalStatusHistory,
  OperationalStatusUpdate,
  PaginatedResponse,
  TokenResponse,
} from '@/types/api'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

class ApiClient {
  private client: AxiosInstance
  private accessToken: string | null = null

  constructor() {
    this.client = axios.create({
      baseURL: `${API_BASE_URL}/v1`,
      headers: {
        'Content-Type': 'application/json',
      },
    })

    // Request interceptor - add auth header
    this.client.interceptors.request.use((config) => {
      const token = this.getToken()
      if (token) {
        config.headers.Authorization = `Bearer ${token}`
      }
      return config
    })

    // Response interceptor - handle auth errors
    this.client.interceptors.response.use(
      (response) => response,
      async (error: AxiosError) => {
        if (error.response?.status === 401) {
          this.clearToken()
          // Redirect to login
          if (typeof window !== 'undefined') {
            window.location.href = '/login'
          }
        }
        return Promise.reject(error)
      }
    )
  }

  // Token management
  setToken(token: string) {
    this.accessToken = token
    if (typeof window !== 'undefined') {
      localStorage.setItem('access_token', token)
    }
  }

  getToken(): string | null {
    if (this.accessToken) return this.accessToken
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('access_token')
      if (token) {
        this.accessToken = token
      }
      return token
    }
    return null
  }

  clearToken() {
    this.accessToken = null
    if (typeof window !== 'undefined') {
      localStorage.removeItem('access_token')
    }
  }

  // ============================================================================
  // Auth endpoints
  // ============================================================================

  async login(email: string, password: string): Promise<TokenResponse> {
    const response = await this.client.post<TokenResponse>('/admin/auth/login', {
      email,
      password,
    })
    this.setToken(response.data.access_token)
    return response.data
  }

  async getMe(): Promise<ApiResponse<AdminUser>> {
    const response = await this.client.get<ApiResponse<AdminUser>>('/admin/auth/me')
    return response.data
  }

  async refreshToken(): Promise<TokenResponse> {
    const response = await this.client.post<TokenResponse>('/admin/auth/refresh')
    this.setToken(response.data.access_token)
    return response.data
  }

  // ============================================================================
  // Status endpoints
  // ============================================================================

  async getOperationalStatus(): Promise<ApiResponse<OperationalStatus>> {
    const response = await this.client.get<ApiResponse<OperationalStatus>>(
      '/admin/status/operational'
    )
    return response.data
  }

  async updateOperationalStatus(
    data: OperationalStatusUpdate
  ): Promise<ApiResponse<OperationalStatus>> {
    const response = await this.client.post<ApiResponse<OperationalStatus>>(
      '/admin/status/operational',
      data
    )
    return response.data
  }

  async getStatusHistory(params?: {
    limit?: number
    offset?: number
  }): Promise<PaginatedResponse<OperationalStatusHistory>> {
    const response = await this.client.get<PaginatedResponse<OperationalStatusHistory>>(
      '/admin/status/history',
      { params }
    )
    return response.data
  }

  // ============================================================================
  // Alert endpoints
  // ============================================================================

  async getAlerts(params?: {
    status?: string
    severity?: string
    search?: string
    limit?: number
    skip?: number
  }): Promise<PaginatedResponse<Alert>> {
    const response = await this.client.get<PaginatedResponse<Alert>>('/admin/alerts', {
      params,
    })
    return response.data
  }

  async getAlert(id: string): Promise<ApiResponse<Alert>> {
    const response = await this.client.get<ApiResponse<Alert>>(`/admin/alerts/${id}`)
    return response.data
  }

  async createAlert(data: AlertCreate, sendImmediately: boolean = false): Promise<ApiResponse<Alert>> {
    const response = await this.client.post<ApiResponse<Alert>>('/admin/alerts', data, {
      params: { send: sendImmediately }
    })
    return response.data
  }

  async cancelAlert(id: string): Promise<ApiResponse<Alert>> {
    const response = await this.client.post<ApiResponse<Alert>>(`/admin/alerts/${id}/cancel`)
    return response.data
  }

  async sendAlert(id: string): Promise<AlertSendResponse> {
    const response = await this.client.post<AlertSendResponse>(`/admin/alerts/${id}/send`)
    return response.data
  }

  async getAlertStats(id: string): Promise<{ success: boolean; data: AlertStats }> {
    const response = await this.client.get<{ success: boolean; data: AlertStats }>(
      `/admin/alerts/${id}/stats`
    )
    return response.data
  }

  // ============================================================================
  // Audit endpoints
  // ============================================================================

  async getAuditLogs(params?: {
    user_id?: string
    action?: string
    resource?: string
    start_date?: string
    end_date?: string
    limit?: number
    offset?: number
  }): Promise<PaginatedResponse<AuditLogEntry>> {
    const response = await this.client.get<PaginatedResponse<AuditLogEntry>>(
      '/admin/audit',
      { params }
    )
    return response.data
  }
}

// Export singleton instance
export const apiClient = new ApiClient()
