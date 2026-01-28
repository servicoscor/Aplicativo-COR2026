'use client'

import { useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from '@/lib/api/client'
import { useAuth } from '@/providers/auth-provider'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Label } from '@/components/ui/label'
import DynamicMap from '@/components/map/DynamicMap'
import {
  cn,
  formatDate,
  getSeverityColor,
  getSeverityName,
  getStatusName,
} from '@/lib/utils'
import {
  AlertCircle,
  ArrowLeft,
  BarChart3,
  Bell,
  CheckCircle,
  Clock,
  Globe,
  Loader2,
  MapPin,
  Send,
  User,
  X,
  XCircle,
} from 'lucide-react'
import type { GeoArea } from '@/components/map/MapContainer'

export default function AlertDetailPage() {
  const { id } = useParams()
  const { user } = useAuth()
  const router = useRouter()
  const queryClient = useQueryClient()
  const [showConfirmSend, setShowConfirmSend] = useState(false)
  const [showConfirmCancel, setShowConfirmCancel] = useState(false)
  const [error, setError] = useState('')

  const canSend = user?.role === 'admin' || user?.role === 'comunicacao'

  const { data, isLoading } = useQuery({
    queryKey: ['alert', id],
    queryFn: () => apiClient.getAlert(id as string),
  })

  const { data: statsData } = useQuery({
    queryKey: ['alertStats', id],
    queryFn: () => apiClient.getAlertStats(id as string),
    enabled: data?.data?.status === 'sent',
  })

  const sendMutation = useMutation({
    mutationFn: () => apiClient.sendAlert(id as string),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['alert', id] })
      queryClient.invalidateQueries({ queryKey: ['alerts'] })
      setShowConfirmSend(false)
    },
    onError: (err: any) => {
      setError(err.response?.data?.detail || 'Erro ao enviar alerta')
    },
  })

  const cancelMutation = useMutation({
    mutationFn: () => apiClient.cancelAlert(id as string),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['alert', id] })
      queryClient.invalidateQueries({ queryKey: ['alerts'] })
      setShowConfirmCancel(false)
    },
    onError: (err: any) => {
      setError(err.response?.data?.detail || 'Erro ao cancelar alerta')
    },
  })

  const alert = data?.data
  const stats = statsData?.data

  // Build geo area for map display
  const getGeoArea = (): GeoArea | null => {
    if (!alert) return null
    if (alert.is_broadcast) return null

    if (alert.target_center_lat && alert.target_center_lng && alert.target_radius) {
      return {
        type: 'circle',
        coordinates: [alert.target_center_lat, alert.target_center_lng],
        radius: alert.target_radius,
      }
    }

    if (alert.target_polygon) {
      return {
        type: 'polygon',
        coordinates: alert.target_polygon,
      }
    }

    return null
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin" />
      </div>
    )
  }

  if (!alert) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">Alerta nao encontrado</p>
        <Link href="/alerts" className="mt-4 inline-block">
          <Button variant="outline">Voltar para Alertas</Button>
        </Link>
      </div>
    )
  }

  const geoArea = getGeoArea()

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link href="/alerts">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Voltar
            </Button>
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">
            Detalhes do Alerta
          </h1>
        </div>
        {canSend && alert.status === 'draft' && (
          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => setShowConfirmCancel(true)}
            >
              <XCircle className="w-4 h-4 mr-2" />
              Cancelar
            </Button>
            <Button onClick={() => setShowConfirmSend(true)}>
              <Send className="w-4 h-4 mr-2" />
              Enviar Agora
            </Button>
          </div>
        )}
      </div>

      {error && (
        <div className="flex items-center gap-2 p-4 text-sm text-red-600 bg-red-50 rounded-lg border border-red-200">
          <AlertCircle className="w-5 h-5" />
          {error}
          <button onClick={() => setError('')} className="ml-auto">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Alert Info */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Bell className="w-5 h-5" />
              Informacoes do Alerta
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-4">
              <span
                className={cn(
                  'inline-flex items-center px-3 py-1 rounded-full text-sm font-medium',
                  alert.severity === 'emergency'
                    ? 'bg-red-100 text-red-800'
                    : alert.severity === 'alert'
                      ? 'bg-yellow-100 text-yellow-800'
                      : 'bg-blue-100 text-blue-800'
                )}
              >
                {getSeverityName(alert.severity)}
              </span>
              <span
                className={cn(
                  'inline-flex items-center px-3 py-1 rounded-full text-sm font-medium',
                  alert.status === 'sent'
                    ? 'bg-green-100 text-green-800'
                    : alert.status === 'canceled'
                      ? 'bg-gray-100 text-gray-800'
                      : 'bg-orange-100 text-orange-800'
                )}
              >
                {getStatusName(alert.status)}
              </span>
            </div>

            <div>
              <Label className="text-gray-500">Titulo</Label>
              <p className="text-lg font-semibold mt-1">{alert.title}</p>
            </div>

            <div>
              <Label className="text-gray-500">Mensagem</Label>
              <p className="mt-1 text-gray-700 whitespace-pre-wrap">
                {alert.body}
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4 pt-4 border-t">
              <div>
                <Label className="text-gray-500">Criado em</Label>
                <p className="mt-1 flex items-center gap-2 text-sm">
                  <Clock className="w-4 h-4" />
                  {formatDate(alert.created_at)}
                </p>
              </div>
              {alert.sent_at && (
                <div>
                  <Label className="text-gray-500">Enviado em</Label>
                  <p className="mt-1 flex items-center gap-2 text-sm">
                    <CheckCircle className="w-4 h-4 text-green-600" />
                    {formatDate(alert.sent_at)}
                  </p>
                </div>
              )}
              {alert.created_by && (
                <div>
                  <Label className="text-gray-500">Criado por</Label>
                  <p className="mt-1 flex items-center gap-2 text-sm">
                    <User className="w-4 h-4" />
                    {alert.created_by}
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Target Area */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <MapPin className="w-5 h-5" />
              Area de Destino
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {alert.is_broadcast ? (
              <div className="p-4 bg-blue-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <Globe className="w-8 h-8 text-blue-600" />
                  <div>
                    <p className="font-medium text-blue-900">
                      Alerta para toda a cidade
                    </p>
                    <p className="text-sm text-blue-700 opacity-80">
                      Todos os usuarios receberam esta notificacao
                    </p>
                  </div>
                </div>
              </div>
            ) : geoArea ? (
              <>
                <div className="p-3 bg-green-50 rounded-lg text-sm text-green-700">
                  <p className="font-medium">Area especifica selecionada</p>
                  <p className="mt-1 opacity-80">
                    Tipo: {geoArea.type === 'circle' ? 'Circulo' : 'Poligono'}
                    {geoArea.type === 'circle' &&
                      geoArea.radius &&
                      ` - Raio: ${(geoArea.radius / 1000).toFixed(1)}km`}
                  </p>
                </div>
                <DynamicMap
                  onAreaChange={() => {}}
                  initialArea={geoArea}
                  readOnly
                />
              </>
            ) : (
              <p className="text-gray-500">Nenhuma area definida</p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Statistics (if sent) */}
      {alert.status === 'sent' && stats && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="w-5 h-5" />
              Estatisticas de Envio
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-4">
              <div className="p-4 bg-gray-50 rounded-lg text-center">
                <p className="text-3xl font-bold text-gray-900">
                  {stats.total_sent || 0}
                </p>
                <p className="text-sm text-gray-500">Total Enviados</p>
              </div>
              <div className="p-4 bg-green-50 rounded-lg text-center">
                <p className="text-3xl font-bold text-green-600">
                  {stats.total_delivered || 0}
                </p>
                <p className="text-sm text-gray-500">Entregues</p>
              </div>
              <div className="p-4 bg-blue-50 rounded-lg text-center">
                <p className="text-3xl font-bold text-blue-600">
                  {stats.total_opened || 0}
                </p>
                <p className="text-sm text-gray-500">Abertos</p>
              </div>
              <div className="p-4 bg-red-50 rounded-lg text-center">
                <p className="text-3xl font-bold text-red-600">
                  {stats.total_failed || 0}
                </p>
                <p className="text-sm text-gray-500">Falhas</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Send Confirmation Modal */}
      {showConfirmSend && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md mx-4 p-6">
            <h2 className="text-lg font-semibold mb-4">Confirmar Envio</h2>
            <p className="text-gray-600 mb-6">
              Tem certeza que deseja enviar este alerta? Esta acao nao pode ser
              desfeita.
            </p>
            <div className="flex gap-3 justify-end">
              <Button
                variant="outline"
                onClick={() => setShowConfirmSend(false)}
                disabled={sendMutation.isPending}
              >
                Cancelar
              </Button>
              <Button
                onClick={() => sendMutation.mutate()}
                disabled={sendMutation.isPending}
              >
                {sendMutation.isPending ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Enviando...
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4 mr-2" />
                    Confirmar Envio
                  </>
                )}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Cancel Confirmation Modal */}
      {showConfirmCancel && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md mx-4 p-6">
            <h2 className="text-lg font-semibold mb-4">Confirmar Cancelamento</h2>
            <p className="text-gray-600 mb-6">
              Tem certeza que deseja cancelar este alerta? Ele nao podera mais
              ser enviado.
            </p>
            <div className="flex gap-3 justify-end">
              <Button
                variant="outline"
                onClick={() => setShowConfirmCancel(false)}
                disabled={cancelMutation.isPending}
              >
                Voltar
              </Button>
              <Button
                variant="destructive"
                onClick={() => cancelMutation.mutate()}
                disabled={cancelMutation.isPending}
              >
                {cancelMutation.isPending ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Cancelando...
                  </>
                ) : (
                  <>
                    <XCircle className="w-4 h-4 mr-2" />
                    Cancelar Alerta
                  </>
                )}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
