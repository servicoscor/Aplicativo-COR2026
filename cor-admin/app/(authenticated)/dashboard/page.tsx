'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from '@/lib/api/client'
import { useAuth } from '@/providers/auth-provider'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  cn,
  formatDate,
  getStageColor,
  getStageTextColor,
  getStageName,
  getHeatColor,
  getHeatTextColor,
  getHeatName,
  getSeverityColor,
  getSeverityName,
  getStatusName,
} from '@/lib/utils'
import {
  AlertCircle,
  Bell,
  Clock,
  Loader2,
  RefreshCw,
  Thermometer,
  X,
} from 'lucide-react'
import { useState } from 'react'
import type { Alert } from '@/types/api'

export default function DashboardPage() {
  const { user } = useAuth()
  const queryClient = useQueryClient()
  const [showStatusModal, setShowStatusModal] = useState(false)

  const canEdit = user?.role === 'admin' || user?.role === 'comunicacao'

  // Fetch operational status
  const { data: statusData, isLoading: statusLoading } = useQuery({
    queryKey: ['operationalStatus'],
    queryFn: () => apiClient.getOperationalStatus(),
    refetchInterval: 30000, // Refresh every 30 seconds
  })

  // Fetch recent alerts
  const { data: alertsData, isLoading: alertsLoading } = useQuery({
    queryKey: ['recentAlerts'],
    queryFn: () => apiClient.getAlerts({ limit: 10 }),
  })

  const status = statusData?.data

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <Button
          variant="outline"
          size="sm"
          onClick={() => {
            queryClient.invalidateQueries({ queryKey: ['operationalStatus'] })
            queryClient.invalidateQueries({ queryKey: ['recentAlerts'] })
          }}
        >
          <RefreshCw className="w-4 h-4 mr-2" />
          Atualizar
        </Button>
      </div>

      {/* Status Card */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-xl font-semibold">
            Status Operacional
          </CardTitle>
          {canEdit && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => setShowStatusModal(true)}
            >
              Alterar Status
            </Button>
          )}
        </CardHeader>
        <CardContent>
          {statusLoading ? (
            <div className="flex items-center justify-center h-24">
              <Loader2 className="w-6 h-6 animate-spin" />
            </div>
          ) : status ? (
            <div className="grid gap-6 md:grid-cols-2">
              {/* City Stage */}
              <div className="space-y-2">
                <Label className="text-sm text-gray-500">Estagio da Cidade</Label>
                <div className="flex items-center gap-4">
                  <div
                    className={cn(
                      'w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold',
                      getStageColor(status.city_stage),
                      getStageTextColor(status.city_stage)
                    )}
                  >
                    {status.city_stage}
                  </div>
                  <div>
                    <p className="text-lg font-semibold">
                      Estagio {status.city_stage}
                    </p>
                    <p className="text-sm text-gray-500">
                      {getStageName(status.city_stage)}
                    </p>
                  </div>
                </div>
              </div>

              {/* Heat Level */}
              <div className="space-y-2">
                <Label className="text-sm text-gray-500">Nivel de Calor</Label>
                <div className="flex items-center gap-4">
                  <div
                    className={cn(
                      'w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold',
                      getHeatColor(status.heat_level),
                      getHeatTextColor(status.heat_level)
                    )}
                  >
                    <Thermometer className="w-8 h-8" />
                  </div>
                  <div>
                    <p className="text-lg font-semibold">NC{status.heat_level}</p>
                    <p className="text-sm text-gray-500">
                      {getHeatName(status.heat_level)}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <p className="text-gray-500">Erro ao carregar status</p>
          )}

          {status && (
            <div className="mt-4 pt-4 border-t text-sm text-gray-500 flex items-center gap-2">
              <Clock className="w-4 h-4" />
              Atualizado em {formatDate(status.updated_at)}
              {status.updated_by && ` por ${status.updated_by}`}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Recent Alerts */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Bell className="w-5 h-5" />
            Alertas Recentes
          </CardTitle>
        </CardHeader>
        <CardContent>
          {alertsLoading ? (
            <div className="flex items-center justify-center h-24">
              <Loader2 className="w-6 h-6 animate-spin" />
            </div>
          ) : alertsData?.data && alertsData.data.length > 0 ? (
            <div className="space-y-3">
              {alertsData.data.map((alert: Alert) => (
                <div
                  key={alert.id}
                  className="flex items-center gap-4 p-3 bg-gray-50 rounded-lg"
                >
                  <div
                    className={cn(
                      'w-2 h-2 rounded-full',
                      getSeverityColor(alert.severity)
                    )}
                  />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-gray-900 truncate">
                      {alert.title}
                    </p>
                    <p className="text-sm text-gray-500">
                      {getSeverityName(alert.severity)} -{' '}
                      {getStatusName(alert.status)}
                    </p>
                  </div>
                  <div className="text-sm text-gray-500">
                    {alert.sent_at
                      ? formatDate(alert.sent_at)
                      : formatDate(alert.created_at)}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500 text-center py-4">
              Nenhum alerta encontrado
            </p>
          )}
        </CardContent>
      </Card>

      {/* Status Update Modal */}
      {showStatusModal && (
        <StatusUpdateModal onClose={() => setShowStatusModal(false)} />
      )}
    </div>
  )
}

function StatusUpdateModal({ onClose }: { onClose: () => void }) {
  const queryClient = useQueryClient()
  const [cityStage, setCityStage] = useState(1)
  const [heatLevel, setHeatLevel] = useState(1)
  const [reason, setReason] = useState('')
  const [error, setError] = useState('')

  // Fetch current status to set initial values
  const { data: statusData } = useQuery({
    queryKey: ['operationalStatus'],
    queryFn: () => apiClient.getOperationalStatus(),
  })

  // Set initial values when data is loaded
  useState(() => {
    if (statusData?.data) {
      setCityStage(statusData.data.city_stage)
      setHeatLevel(statusData.data.heat_level)
    }
  })

  const mutation = useMutation({
    mutationFn: () =>
      apiClient.updateOperationalStatus({
        city_stage: cityStage,
        heat_level: heatLevel,
        reason,
        source: 'manual',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['operationalStatus'] })
      onClose()
    },
    onError: (err: any) => {
      setError(err.response?.data?.detail || 'Erro ao atualizar status')
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!reason.trim()) {
      setError('Motivo e obrigatorio')
      return
    }
    mutation.mutate()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-md mx-4">
        <div className="flex items-center justify-between p-4 border-b">
          <h2 className="text-lg font-semibold">Alterar Status Operacional</h2>
          <button onClick={onClose}>
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-4 space-y-4">
          {error && (
            <div className="flex items-center gap-2 p-3 text-sm text-red-600 bg-red-50 rounded-md">
              <AlertCircle className="w-4 h-4" />
              {error}
            </div>
          )}

          <div className="space-y-2">
            <Label>Estagio da Cidade</Label>
            <div className="flex gap-2">
              {[1, 2, 3, 4, 5].map((stage) => (
                <button
                  key={stage}
                  type="button"
                  className={cn(
                    'w-10 h-10 rounded-full font-bold transition-all',
                    getStageColor(stage),
                    getStageTextColor(stage),
                    cityStage === stage
                      ? 'ring-2 ring-offset-2 ring-gray-900'
                      : 'opacity-60 hover:opacity-100'
                  )}
                  onClick={() => setCityStage(stage)}
                >
                  {stage}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label>Nivel de Calor</Label>
            <div className="flex gap-2">
              {[1, 2, 3, 4, 5].map((level) => (
                <button
                  key={level}
                  type="button"
                  className={cn(
                    'w-10 h-10 rounded-full font-bold transition-all',
                    getHeatColor(level),
                    getHeatTextColor(level),
                    heatLevel === level
                      ? 'ring-2 ring-offset-2 ring-gray-900'
                      : 'opacity-60 hover:opacity-100'
                  )}
                  onClick={() => setHeatLevel(level)}
                >
                  {level}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="reason">Motivo da Alteracao *</Label>
            <Input
              id="reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Ex: Previsao de chuvas fortes"
              required
            />
          </div>

          <div className="flex gap-3 pt-2">
            <Button
              type="button"
              variant="outline"
              className="flex-1"
              onClick={onClose}
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              className="flex-1"
              disabled={mutation.isPending}
            >
              {mutation.isPending ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Salvando...
                </>
              ) : (
                'Salvar'
              )}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
