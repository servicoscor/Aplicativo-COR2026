'use client'

import dynamic from 'next/dynamic'
import { Loader2 } from 'lucide-react'

const MapContainer = dynamic(() => import('./MapContainer'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-[400px] rounded-lg border border-gray-200 flex items-center justify-center bg-gray-50">
      <Loader2 className="w-6 h-6 animate-spin text-gray-400" />
    </div>
  ),
})

export default MapContainer
export type { GeoArea } from './MapContainer'
