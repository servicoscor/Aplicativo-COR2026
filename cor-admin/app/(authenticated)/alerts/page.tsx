'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { apiClient } from '@/lib/api/client'
import { useAuth } from '@/providers/auth-provider'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  cn,
  formatDate,
  getSeverityColor,
  getSeverityName,
  getStatusName,
} from '@/lib/utils'
import {
  Bell,
  ChevronLeft,
  ChevronRight,
  Filter,
  Loader2,
  Plus,
  Search,
  X,
} from 'lucide-react'
import type { Alert } from '@/types/api'

const SEVERITY_OPTIONS = [
  { value: '', label: 'Todas' },
  { value: 'info', label: 'Informativo' },
  { value: 'alert', label: 'Alerta' },
  { value: 'emergency', label: 'Emergencia' },
]

const STATUS_OPTIONS = [
  { value: '', label: 'Todos' },
  { value: 'draft', label: 'Rascunho' },
  { value: 'sent', label: 'Enviado' },
  { value: 'canceled', label: 'Cancelado' },
]

export default function AlertsPage() {
  const { user } = useAuth()
  const [page, setPage] = useState(1)
  const [showFilters, setShowFilters] = useState(false)
  const [search, setSearch] = useState('')
  const [severity, setSeverity] = useState('')
  const [status, setStatus] = useState('')
  const limit = 20

  const canCreate = user?.role === 'admin' || user?.role === 'comunicacao'

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ['alerts', page, search, severity, status],
    queryFn: () =>
      apiClient.getAlerts({
        skip: (page - 1) * limit,
        limit,
        search: search || undefined,
        severity: severity || undefined,
        status: status || undefined,
      }),
  })

  const alerts = data?.data || []
  const total = data?.total || 0
  const totalPages = Math.ceil(total / limit)

  const clearFilters = () => {
    setSearch('')
    setSeverity('')
    setStatus('')
    setPage(1)
  }

  const hasFilters = search || severity || status

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Alertas</h1>
        {canCreate && (
          <Link href="/alerts/new">
            <Button>
              <Plus className="w-4 h-4 mr-2" />
              Novo Alerta
            </Button>
          </Link>
        )}
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
            <div className="grid gap-4 md:grid-cols-3">
              <div className="space-y-2">
                <Label htmlFor="search">Buscar</Label>
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <Input
                    id="search"
                    placeholder="Titulo ou conteudo..."
                    value={search}
                    onChange={(e) => {
                      setSearch(e.target.value)
                      setPage(1)
                    }}
                    className="pl-10"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="severity">Severidade</Label>
                <select
                  id="severity"
                  value={severity}
                  onChange={(e) => {
                    setSeverity(e.target.value)
                    setPage(1)
                  }}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                >
                  {SEVERITY_OPTIONS.map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="status">Status</Label>
                <select
                  id="status"
                  value={status}
                  onChange={(e) => {
                    setStatus(e.target.value)
                    setPage(1)
                  }}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                >
                  {STATUS_OPTIONS.map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </CardContent>
        )}
      </Card>

      {/* Alerts List */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="flex items-center gap-2">
            <Bell className="w-5 h-5" />
            Lista de Alertas
          </CardTitle>
          {isFetching && <Loader2 className="w-4 h-4 animate-spin" />}
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex items-center justify-center h-48">
              <Loader2 className="w-6 h-6 animate-spin" />
            </div>
          ) : alerts.length > 0 ? (
            <>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Titulo
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Severidade
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Status
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Criado em
                      </th>
                      <th className="px-4 py-3 text-left font-medium text-gray-500">
                        Enviado em
                      </th>
                      <th className="px-4 py-3 text-right font-medium text-gray-500">
                        Acoes
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {alerts.map((alert: Alert) => (
                      <tr key={alert.id} className="border-b hover:bg-gray-50">
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <div
                              className={cn(
                                'w-2 h-2 rounded-full',
                                getSeverityColor(alert.severity)
                              )}
                            />
                            <span className="font-medium text-gray-900">
                              {alert.title}
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={cn(
                              'inline-flex items-center px-2 py-1 rounded text-xs font-medium',
                              alert.severity === 'emergency'
                                ? 'bg-red-100 text-red-800'
                                : alert.severity === 'alert'
                                  ? 'bg-yellow-100 text-yellow-800'
                                  : 'bg-blue-100 text-blue-800'
                            )}
                          >
                            {getSeverityName(alert.severity)}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={cn(
                              'inline-flex items-center px-2 py-1 rounded text-xs font-medium',
                              alert.status === 'sent'
                                ? 'bg-green-100 text-green-800'
                                : alert.status === 'canceled'
                                  ? 'bg-gray-100 text-gray-800'
                                  : 'bg-orange-100 text-orange-800'
                            )}
                          >
                            {getStatusName(alert.status)}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-gray-500">
                          {formatDate(alert.created_at)}
                        </td>
                        <td className="px-4 py-3 text-gray-500">
                          {alert.sent_at ? formatDate(alert.sent_at) : '-'}
                        </td>
                        <td className="px-4 py-3 text-right">
                          <Link href={`/alerts/${alert.id}`}>
                            <Button variant="ghost" size="sm">
                              Ver
                            </Button>
                          </Link>
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
                    {Math.min(page * limit, total)} de {total} alertas
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
              Nenhum alerta encontrado
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
