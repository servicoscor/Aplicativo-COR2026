'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { apiClient } from '@/lib/api/client'
import { useAuth } from '@/providers/auth-provider'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { cn, formatDate } from '@/lib/utils'
import {
  ChevronLeft,
  ChevronRight,
  FileText,
  Filter,
  Loader2,
  Search,
  X,
} from 'lucide-react'
import type { AuditLogEntry } from '@/types/api'

const ACTION_OPTIONS = [
  { value: '', label: 'Todas' },
  { value: 'create_alert', label: 'Criar Alerta' },
  { value: 'send_alert', label: 'Enviar Alerta' },
  { value: 'cancel_alert', label: 'Cancelar Alerta' },
  { value: 'change_status', label: 'Alterar Status' },
  { value: 'login', label: 'Login' },
]

const RESOURCE_OPTIONS = [
  { value: '', label: 'Todos' },
  { value: 'alert', label: 'Alerta' },
  { value: 'status', label: 'Status' },
  { value: 'auth', label: 'Autenticacao' },
]

function getActionLabel(action: string): string {
  const labels: Record<string, string> = {
    create_alert: 'Criar Alerta',
    send_alert: 'Enviar Alerta',
    cancel_alert: 'Cancelar Alerta',
    change_status: 'Alterar Status',
    login: 'Login',
    logout: 'Logout',
  }
  return labels[action] || action
}

function getResourceLabel(resource: string): string {
  const labels: Record<string, string> = {
    alert: 'Alerta',
    status: 'Status',
    auth: 'Autenticacao',
  }
  return labels[resource] || resource
}

function getActionColor(action: string): string {
  if (action.includes('create')) return 'bg-green-100 text-green-800'
  if (action.includes('send')) return 'bg-blue-100 text-blue-800'
  if (action.includes('cancel') || action.includes('delete')) return 'bg-red-100 text-red-800'
  if (action.includes('change') || action.includes('update')) return 'bg-yellow-100 text-yellow-800'
  return 'bg-gray-100 text-gray-800'
}

export default function AuditPage() {
  const { user } = useAuth()
  const router = useRouter()
  const [page, setPage] = useState(1)
  const [showFilters, setShowFilters] = useState(false)
  const [action, setAction] = useState('')
  const [resource, setResource] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const limit = 50

  // Only admin can access audit logs
  if (user && user.role !== 'admin') {
    router.push('/dashboard')
    return null
  }

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ['auditLogs', page, action, resource, startDate, endDate],
    queryFn: () =>
      apiClient.getAuditLogs({
        skip: (page - 1) * limit,
        limit,
        action: action || undefined,
        resource: resource || undefined,
        start_date: startDate || undefined,
        end_date: endDate || undefined,
      }),
    enabled: user?.role === 'admin',
  })

  const logs = data?.data || []
  const total = data?.total || 0
  const totalPages = Math.ceil(total / limit)

  const clearFilters = () => {
    setAction('')
    setResource('')
    setStartDate('')
    setEndDate('')
    setPage(1)
  }

  const hasFilters = action || resource || startDate || endDate

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Auditoria</h1>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base font-medium">Filtros</CardTitle>
            <div className="flex items-center gap-2">
              {hasFilters && (
                <Button variant="ghost" size="sm" onClick={clearFilters}>
                  <X className="w-4 h-4 mr-1" />
                  Limpar
                </Button>
              )}
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowFilters(!showFilters)}
              >
                <Filter className="w-4 h-4 mr-2" />
                {showFilters ? 'Ocultar' : 'Mostrar'}
              </Button>
            </div>
          </div>
        </CardHeader>
        {showFilters && (
          <CardContent className="pt-0">
            <div className="grid gap-4 md:grid-cols-4">
              <div className="space-y-2">
                <Label htmlFor="action">Acao</Label>
                <select
                  id="action"
                  value={action}
                  onChange={(e) => {
                    setAction(e.target.value)
                    setPage(1)
                  }}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                >
                  {ACTION_OPTIONS.map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="resource">Recurso</Label>
                <select
                  id="resource"
                  value={resource}
                  onChange={(e) => {
                    setResource(e.target.value)
                    setPage(1)
                  }}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                >
                  {RESOURCE_OPTIONS.map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="startDate">Data Inicio</Label>
                <Input
                  id="startDate"
                  type="date"
                  value={startDate}
                  onChange={(e) => {
                    setStartDate(e.target.value)
                    setPage(1)
                  }}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="endDate">Data Fim</Label>
                <Input
                  id="endDate"
                  type="date"
                  value={endDate}
                  onChange={(e) => {
                    setEndDate(e.target.value)
                    setPage(1)
                  }}
                />
              </div>
            </div>
          </CardContent>
        )}
      </Card>

      {/* Audit Logs Table */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="flex items-center gap-2">
            <FileText className="w-5 h-5" />
            Logs de Auditoria
          </CardTitle>
          {isFetching && <Loader2 className="w-4 h-4 animate-spin" />}
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex items-center justify-center h-48">
              <Loader2 className="w-6 h-6 animate-spin" />
            </div>
          ) : logs.length > 0 ? (
            <>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Data/Hora
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Usuario
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Acao
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Recurso
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Detalhes
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        IP
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {logs.map((log: AuditLogEntry) => (
                      <tr key={log.id} className="border-b hover:bg-gray-50">
                        <td className="px-4 py-3 whitespace-nowrap text-gray-500">
                          {formatDate(log.created_at)}
                        </td>
                        <td className="px-4 py-3">
                          <div>
                            <p className="font-medium text-gray-900">
                              {log.user_name || 'Desconhecido'}
                            </p>
                            <p className="text-xs text-gray-500">
                              {log.user_email}
                            </p>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={cn(
                              'inline-flex items-center px-2 py-1 rounded text-xs font-medium',
                              getActionColor(log.action)
                            )}
                          >
                            {getActionLabel(log.action)}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-gray-100 text-gray-800">
                            {getResourceLabel(log.resource)}
                          </span>
                          {log.resource_id && (
                            <p className="text-xs text-gray-500 mt-1">
                              ID: {log.resource_id.slice(0, 8)}...
                            </p>
                          )}
                        </td>
                        <td className="px-4 py-3 max-w-xs">
                          {log.payload_summary ? (
                            <div className="text-xs text-gray-600 truncate">
                              {typeof log.payload_summary === 'string'
                                ? log.payload_summary
                                : JSON.stringify(log.payload_summary)}
                            </div>
                          ) : (
                            <span className="text-gray-400">-</span>
                          )}
                        </td>
                        <td className="px-4 py-3 text-gray-500 text-xs font-mono">
                          {log.ip_address || '-'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Pagination */}
              {totalPages > 1 && (
                <div className="flex items-center justify-between mt-4 pt-4 border-t">
                  <p className="text-sm text-gray-500">
                    Mostrando {(page - 1) * limit + 1} a{' '}
                    {Math.min(page * limit, total)} de {total} registros
                  </p>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setPage((p) => Math.max(1, p - 1))}
                      disabled={page === 1}
                    >
                      <ChevronLeft className="w-4 h-4" />
                    </Button>
                    <span className="text-sm text-gray-600">
                      Pagina {page} de {totalPages}
                    </span>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                      disabled={page === totalPages}
                    >
                      <ChevronRight className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              )}
            </>
          ) : (
            <p className="text-gray-500 text-center py-8">
              Nenhum registro de auditoria encontrado
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
