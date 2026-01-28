'use client'

import { useEffect, useRef, useState } from 'react'
import L from 'leaflet'
import 'leaflet-draw'
import type { AlertArea, CircleArea } from '@/types/alert'

// Rio de Janeiro center coordinates
const RIO_CENTER: [number, number] = [-22.9068, -43.1729]
const DEFAULT_ZOOM = 11

interface AlertMapProps {
  onAreasChange: (areas: AlertArea[], circles: CircleArea[]) => void
}

export function AlertMap({ onAreasChange }: AlertMapProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | null>(null)
  const drawnItemsRef = useRef<L.FeatureGroup | null>(null)
  const [isClient, setIsClient] = useState(false)

  useEffect(() => {
    setIsClient(true)
  }, [])

  useEffect(() => {
    if (!isClient || !mapContainerRef.current || mapRef.current) return

    // Initialize map
    const map = L.map(mapContainerRef.current).setView(RIO_CENTER, DEFAULT_ZOOM)
    mapRef.current = map

    // Add tile layer
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
      subdomains: 'abcd',
      maxZoom: 19,
    }).addTo(map)

    // Initialize feature group for drawn items
    const drawnItems = new L.FeatureGroup()
    drawnItemsRef.current = drawnItems
    map.addLayer(drawnItems)

    // Initialize draw control
    const drawControl = new L.Control.Draw({
      position: 'topright',
      draw: {
        polyline: false,
        marker: false,
        circlemarker: false,
        rectangle: {
          shapeOptions: {
            color: '#FF6B35',
            fillColor: '#FF6B35',
            fillOpacity: 0.3,
            weight: 2,
          },
        },
        polygon: {
          allowIntersection: false,
          showArea: true,
          shapeOptions: {
            color: '#FF6B35',
            fillColor: '#FF6B35',
            fillOpacity: 0.3,
            weight: 2,
          },
        },
        circle: {
          shapeOptions: {
            color: '#FF6B35',
            fillColor: '#FF6B35',
            fillOpacity: 0.3,
            weight: 2,
          },
        },
      },
      edit: {
        featureGroup: drawnItems,
        remove: true,
      },
    })
    map.addControl(drawControl)

    // Handle draw events
    const updateAreas = () => {
      const areas: AlertArea[] = []
      const circles: CircleArea[] = []

      drawnItems.eachLayer((layer: L.Layer) => {
        if (layer instanceof L.Circle) {
          const center = layer.getLatLng()
          const radiusMeters = layer.getRadius()
          circles.push({
            center: [center.lat, center.lng],
            radius_km: radiusMeters / 1000,
          })
        } else if (layer instanceof L.Polygon || layer instanceof L.Rectangle) {
          const geoJson = layer.toGeoJSON()
          if (geoJson.type === 'Feature') {
            areas.push({
              type: 'Feature',
              geometry: geoJson.geometry as AlertArea['geometry'],
              properties: {},
            })
          }
        }
      })

      onAreasChange(areas, circles)
    }

    map.on(L.Draw.Event.CREATED, (e: L.LeafletEvent) => {
      const event = e as L.DrawEvents.Created
      drawnItems.addLayer(event.layer)
      updateAreas()
    })

    map.on(L.Draw.Event.EDITED, () => {
      updateAreas()
    })

    map.on(L.Draw.Event.DELETED, () => {
      updateAreas()
    })

    // Cleanup
    return () => {
      map.remove()
      mapRef.current = null
      drawnItemsRef.current = null
    }
  }, [isClient, onAreasChange])

  if (!isClient) {
    return (
      <div className="w-full h-full bg-cor-dark/50 rounded-lg flex items-center justify-center">
        <span className="text-gray-400">Carregando mapa...</span>
      </div>
    )
  }

  return (
    <div
      ref={mapContainerRef}
      className="w-full h-full min-h-[400px] rounded-lg"
    />
  )
}
