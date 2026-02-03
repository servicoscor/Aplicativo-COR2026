'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useAuthStore } from '@/lib/store'
import { alertsApi, ApiError } from '@/lib/api'
import type { Alert, AlertListResponse } from '@/types/alert'
import { format } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import {
  Bell,
  AlertTriangle,
  AlertCircle,
  Info,
  Send,
  Clock,
  CheckCircle,
  XCircle,
  PlusCircle,
  RefreshCw,
  Loader2,
} from 'lucide-react'

const severityConfig = {
  info: { icon: Info, color: 'text-blue-400', bg: 'bg-blue-500/10', label: 'Informativo' },
  alert: { icon: AlertTriangle, color: 'text-yellow-400', bg: 'bg-yellow-500/10', label: 'Alerta' },
  emergency: { icon: AlertCircle, color: 'text-red-400', bg: 'bg-red-500/10', label: 'Emergência' },
}

const statusConfig = {
  draft: { icon: Clock, color: 'text-gray-400', bg: 'bg-gray-500/10', label: 'Rascunho' },
  sent: { icon: CheckCircle, color: 'text-green-400', bg: 'bg-green-500/10', label: 'Enviado' },
  canceled: { icon: XCircle, color: 'text-red-400', bg: 'bg-red-500/10', label: 'Cancelado' },
}

export default function AlertsPage() {
  const { apiKey } = useAuthStore()
  const [alerts, setAlerts] = useState<Alert[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('')
  const [sendingId, setSendingId] = useState<string | null>(null)

  const fetchAlerts = async () => {
    if (!apiKey) return
    setLoading(true)
    setError('')
    try {
      const response = await alertsApi.list(apiKey, {
        status: statusFilter || undefined,
        page_size: 50,
      })
      setAlerts(response.data ?? [])
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('Erro ao carregar alertas')
      }
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAlerts()
  }, [apiKey, statusFilter])

  const handleSend = async (alertId: string) => {
    if (!apiKey) return
    setSendingId(alertId)
    try {
      await alertsApi.send(apiKey, alertId)
      await fetchAlerts()
    } catch (err) {
      if (err instanceof ApiError) {
        alert(`Erro ao enviar: ${err.message}`)
      }
    } finally {
      setSendingId(null)
    }
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-3">
            <Bell className="w-7 h-7 text-cor-orange" />
            Alertas
          </h1>
          <p className="text-gray-400 mt-1">Gerencie os alertas georreferenciados</p>
        </div>
        <div className="flex items-center gap-4">
          <button
            onClick={fetchAlerts}
            disabled={loading}
            className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-gray-300 transition-colors"
          >
            <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <Link
            href="/alerts/new"
            className="flex items-center gap-2 px-4 py-2 bg-cor-orange hover:bg-cor-orange/90 text-white font-semibold rounded-lg transition-colors"
          >
            <PlusCircle className="w-5 h-5" />
            Novo Alerta
          </Link>
        </div>
      </div>

      {/* Filters */}
      <div className="mb-6 flex gap-2">
        <button
          onClick={() => setStatusFilter('')}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            statusFilter === ''
              ? 'bg-cor-orange text-white'
              : 'bg-white/5 text-gray-300 hover:bg-white/10'
          }`}
        >
          Todos
        </button>
        <button
          onClick={() => setStatusFilter('draft')}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            statusFilter === 'draft'
              ? 'bg-cor-orange text-white'
              : 'bg-white/5 text-gray-300 hover:bg-white/10'
          }`}
        >
          Rascunhos
        </button>
        <button
          onClick={() => setStatusFilter('sent')}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            statusFilter === 'sent'
              ? 'bg-cor-orange text-white'
              : 'bg-white/5 text-gray-300 hover:bg-white/10'
          }`}
        >
          Enviados
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400">
          {error}
        </div>
      )}

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 text-cor-orange animate-spin" />
        </div>
      )}

      {/* Empty State */}
      {!loading && alerts.length === 0 && (
        <div className="text-center py-12">
          <Bell className="w-12 h-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-400">Nenhum alerta encontrado</h3>
          <p className="text-gray-500 mt-1">Crie um novo alerta para começar</p>
        </div>
      )}

      {/* Alerts List */}
      {!loading && alerts.length > 0 && (
        <div className="space-y-4">
          {alerts.map((alert) => {
            const severity = severityConfig[alert.severity]
            const status = statusConfig[alert.status]
            const SeverityIcon = severity.icon
            const StatusIcon = status.icon

            return (
              <div
                key={alert.id}
                className="bg-cor-blue/30 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:border-white/20 transition-all"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${severity.bg} ${severity.color}`}>
                        <SeverityIcon className="w-3.5 h-3.5" />
                        {severity.label}
                      </span>
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${status.bg} ${status.color}`}>
                        <StatusIcon className="w-3.5 h-3.5" />
                        {status.label}
                      </span>
                      {alert.broadcast && (
                        <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-purple-500/10 text-purple-400">
                          Broadcast
                        </span>
                      )}
                    </div>
                    <h3 className="text-lg font-semibold text-white mb-1">{alert.title}</h3>
                    <p className="text-gray-400 text-sm line-clamp-2">{alert.body}</p>
                    <div className="mt-3 flex items-center gap-4 text-xs text-gray-500">
                      <span>ID: {alert.id.slice(0, 8)}...</span>
                      <span>
                        Criado: {format(new Date(alert.created_at), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR })}
                      </span>
                      {alert.sent_at && (
                        <span>
                          Enviado: {format(new Date(alert.sent_at), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR })}
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="ml-4">
                    {alert.status === 'draft' && (
                      <button
                        onClick={() => handleSend(alert.id)}
                        disabled={sendingId === alert.id}
                        className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 text-white font-medium rounded-lg transition-colors"
                      >
                        {sendingId === alert.id ? (
                          <Loader2 className="w-4 h-4 animate-spin" />
                        ) : (
                          <Send className="w-4 h-4" />
                        )}
                        Enviar
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
