import 'leaflet'
import 'leaflet-draw'

declare module 'leaflet' {
  namespace Control {
    class Draw extends Control {
      constructor(options?: DrawConstructorOptions)
    }
  }

  namespace Draw {
    namespace Event {
      const CREATED: string
      const EDITED: string
      const DELETED: string
      const DRAWSTART: string
      const DRAWSTOP: string
      const DRAWVERTEX: string
      const EDITSTART: string
      const EDITMOVE: string
      const EDITRESIZE: string
      const EDITVERTEX: string
      const EDITSTOP: string
      const DELETESTART: string
      const DELETESTOP: string
      const TOOLBARCLOSED: string
      const TOOLBAROPENED: string
      const MARKERCONTEXT: string
    }
  }

  interface DrawConstructorOptions {
    position?: ControlPosition
    draw?: DrawOptions
    edit?: EditOptions
  }

  interface DrawOptions {
    polyline?: DrawOptions.PolylineOptions | false
    polygon?: DrawOptions.PolygonOptions | false
    rectangle?: DrawOptions.RectangleOptions | false
    circle?: DrawOptions.CircleOptions | false
    marker?: DrawOptions.MarkerOptions | false
    circlemarker?: DrawOptions.CircleMarkerOptions | false
  }

  namespace DrawOptions {
    interface PolylineOptions {
      allowIntersection?: boolean
      repeatMode?: boolean
      drawError?: DrawErrorOptions
      guidelineDistance?: number
      shapeOptions?: PolylineOptions
      metric?: boolean
      feet?: boolean
      zIndexOffset?: number
    }

    interface PolygonOptions extends PolylineOptions {
      showArea?: boolean
    }

    interface RectangleOptions {
      shapeOptions?: PathOptions
      repeatMode?: boolean
    }

    interface CircleOptions {
      shapeOptions?: PathOptions
      showRadius?: boolean
      metric?: boolean
      feet?: boolean
      repeatMode?: boolean
    }

    interface MarkerOptions {
      icon?: Icon
      zIndexOffset?: number
      repeatMode?: boolean
    }

    interface CircleMarkerOptions {
      stroke?: boolean
      color?: string
      weight?: number
      opacity?: number
      fill?: boolean
      fillColor?: string
      fillOpacity?: number
      repeatMode?: boolean
    }

    interface DrawErrorOptions {
      color?: string
      timeout?: number
      message?: string
    }
  }

  interface EditOptions {
    featureGroup: FeatureGroup
    remove?: boolean
    edit?: EditHandlerOptions | false
  }

  interface EditHandlerOptions {
    selectedPathOptions?: PathOptions
  }

  namespace DrawEvents {
    interface Created extends LeafletEvent {
      layer: Layer
      layerType: string
    }

    interface Edited extends LeafletEvent {
      layers: LayerGroup
    }

    interface Deleted extends LeafletEvent {
      layers: LayerGroup
    }
  }
}
