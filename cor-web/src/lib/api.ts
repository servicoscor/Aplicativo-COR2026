import type { Alert, AlertCreate, AlertListResponse, AlertSendResponse } from '@/types/alert'

const API_URL = process.env.NEXT_PUBLIC_API_URL || '/api'

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message)
    this.name = 'ApiError'
  }
}

async function fetchApi<T>(
  endpoint: string,
  options: RequestInit = {},
  apiKey?: string
): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }

  if (apiKey) {
    headers['X-API-Key'] = apiKey
  }

  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers,
  })

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}))
    throw new ApiError(
      response.status,
      errorData.detail || `HTTP error ${response.status}`
    )
  }

  return response.json()
}

export const alertsApi = {
  list: async (
    apiKey: string,
    params?: { status?: string; page?: number; page_size?: number }
  ): Promise<AlertListResponse> => {
    const searchParams = new URLSearchParams()
    if (params?.status) searchParams.set('status', params.status)
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.page_size) searchParams.set('page_size', params.page_size.toString())

    const query = searchParams.toString()
    return fetchApi<AlertListResponse>(
      `/v1/alerts${query ? `?${query}` : ''}`,
      { method: 'GET' },
      apiKey
    )
  },

  get: async (apiKey: string, alertId: string): Promise<Alert> => {
    return fetchApi<Alert>(`/v1/alerts/${alertId}`, { method: 'GET' }, apiKey)
  },

  create: async (apiKey: string, data: AlertCreate): Promise<Alert> => {
    return fetchApi<Alert>(
      '/v1/alerts',
      {
        method: 'POST',
        body: JSON.stringify(data),
      },
      apiKey
    )
  },

  send: async (apiKey: string, alertId: string): Promise<AlertSendResponse> => {
    return fetchApi<AlertSendResponse>(
      `/v1/alerts/${alertId}/send`,
      { method: 'POST' },
      apiKey
    )
  },
}

export const healthApi = {
  check: async (): Promise<{ status: string; version: string }> => {
    return fetchApi('/v1/health', { method: 'GET' })
  },
}

export { ApiError }
