'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

// Fix Leaflet default marker icon issue
delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
})

// Load leaflet-draw CSS dynamically (only once)
let cssLoaded = false
if (typeof window !== 'undefined' && !cssLoaded) {
  const existingLink = document.querySelector('link[href*="leaflet.draw.css"]')
  if (!existingLink) {
    const link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = 'https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.css'
    document.head.appendChild(link)
  }
  cssLoaded = true
}

export interface GeoArea {
  type: 'circle' | 'polygon'
  coordinates: number[] | number[][]
  radius?: number
}

interface MapContainerProps {
  onAreaChange: (area: GeoArea | null) => void
  initialArea?: GeoArea | null
  readOnly?: boolean
}

export default function MapContainer({
  onAreaChange,
  initialArea,
  readOnly = false,
}: MapContainerProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null)
  const mapInstanceRef = useRef<L.Map | null>(null)
  const drawnItemsRef = useRef<L.FeatureGroup | null>(null)
  const [isReady, setIsReady] = useState(false)
  const initializingRef = useRef(false)

  const handleAreaChange = useCallback((area: GeoArea | null) => {
    onAreaChange(area)
  }, [onAreaChange])

  useEffect(() => {
    // Prevent double initialization
    if (initializingRef.current || mapInstanceRef.current) return
    if (!mapContainerRef.current) return

    initializingRef.current = true

    const initMap = async () => {
      try {
        // Dynamically import leaflet-draw
        await import('leaflet-draw')

        // Check again after async import
        if (!mapContainerRef.current || mapInstanceRef.current) {
          initializingRef.current = false
          return
        }

        // Rio de Janeiro center coordinates
        const rioCenter: L.LatLngTuple = [-22.9068, -43.1729]

        // Initialize map
        const map = L.map(mapContainerRef.current).setView(rioCenter, 11)
        mapInstanceRef.current = map

        // Add tile layer
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; OpenStreetMap contributors',
        }).addTo(map)

        // Create feature group for drawn items
        const drawnItems = new L.FeatureGroup()
        map.addLayer(drawnItems)
        drawnItemsRef.current = drawnItems

        if (!readOnly) {
          // Initialize draw control
          const drawControl = new (L.Control as any).Draw({
            position: 'topright',
            draw: {
              polyline: false,
              marker: false,
              circlemarker: false,
              rectangle: false,
              polygon: {
                allowIntersection: false,
                showArea: true,
                drawError: {
                  color: '#e1e1e1',
                  message: '<strong>Erro:</strong> Poligono invalido!',
                },
                shapeOptions: {
                  color: '#3b82f6',
                  fillOpacity: 0.3,
                },
              },
              circle: {
                shapeOptions: {
                  color: '#3b82f6',
                  fillOpacity: 0.3,
                },
                showRadius: true,
                metric: true,
              },
            },
            edit: {
              featureGroup: drawnItems,
              remove: true,
            },
          })
          map.addControl(drawControl)

          // Handle draw events
          map.on((L as any).Draw.Event.CREATED, (event: any) => {
            const layer = event.layer
            drawnItems.clearLayers()
            drawnItems.addLayer(layer)

            if (layer instanceof L.Circle) {
              const center = layer.getLatLng()
              const radius = layer.getRadius()
              handleAreaChange({
                type: 'circle',
                coordinates: [center.lat, center.lng],
                radius,
              })
            } else if (layer instanceof L.Polygon) {
              const latlngs = layer.getLatLngs()[0] as L.LatLng[]
              const coordinates = latlngs.map((ll) => [ll.lat, ll.lng])
              handleAreaChange({
                type: 'polygon',
                coordinates,
              })
            }
          })

          map.on((L as any).Draw.Event.EDITED, (event: any) => {
            const layers = event.layers
            layers.eachLayer((layer: any) => {
              if (layer instanceof L.Circle) {
                const center = layer.getLatLng()
                const radius = layer.getRadius()
                handleAreaChange({
                  type: 'circle',
                  coordinates: [center.lat, center.lng],
                  radius,
                })
              } else if (layer instanceof L.Polygon) {
                const latlngs = layer.getLatLngs()[0] as L.LatLng[]
                const coordinates = latlngs.map((ll) => [ll.lat, ll.lng])
                handleAreaChange({
                  type: 'polygon',
                  coordinates,
                })
              }
            })
          })

          map.on((L as any).Draw.Event.DELETED, () => {
            handleAreaChange(null)
          })
        }

        setIsReady(true)
      } catch (error) {
        console.error('Failed to initialize map:', error)
      } finally {
        initializingRef.current = false
      }
    }

    initMap()

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove()
        mapInstanceRef.current = null
      }
      drawnItemsRef.current = null
      setIsReady(false)
    }
  }, [readOnly, handleAreaChange])

  // Load initial area
  useEffect(() => {
    if (!isReady || !initialArea || !drawnItemsRef.current || !mapInstanceRef.current) return

    drawnItemsRef.current.clearLayers()

    if (initialArea.type === 'circle' && initialArea.radius) {
      const [lat, lng] = initialArea.coordinates as number[]
      const circle = L.circle([lat, lng], {
        radius: initialArea.radius,
        color: '#3b82f6',
        fillOpacity: 0.3,
      })
      drawnItemsRef.current.addLayer(circle)
      mapInstanceRef.current.fitBounds(circle.getBounds())
    } else if (initialArea.type === 'polygon') {
      const latlngs = (initialArea.coordinates as number[][]).map(
        ([lat, lng]) => [lat, lng] as L.LatLngTuple
      )
      const polygon = L.polygon(latlngs, {
        color: '#3b82f6',
        fillOpacity: 0.3,
      })
      drawnItemsRef.current.addLayer(polygon)
      mapInstanceRef.current.fitBounds(polygon.getBounds())
    }
  }, [isReady, initialArea])

  return (
    <div
      ref={mapContainerRef}
      className="w-full h-[400px] rounded-lg border border-gray-200"
    />
  )
}
