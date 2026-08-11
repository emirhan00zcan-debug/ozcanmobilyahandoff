// Tüm konum/ölçü alanları tam sayı milimetre cinsindendir — kayan noktalı
// biriktirme hatalarından kaçınmak için gerçek kaynak veri hep mm'dir, canvas
// pikseli yalnızca çizim anında türetilir (bkz. Mimari Doküman §3).

export interface Point {
  x: number;
  y: number;
}

export interface Wall {
  id: string;
  start: Point;
  end: Point;
  thicknessMm: number;
}

export type OpeningType = "door" | "window";

// offsetMm, wall.start'tan itibaren duvar boyunca mesafedir (bkz. §5 JSON şema).
export interface Opening {
  id: string;
  wallId: string;
  type: OpeningType;
  offsetMm: number;
  widthMm: number;
  heightMm: number;
  sillHeightMm: number;
}

export interface Room {
  id: string;
  dimensionsMm: { width: number; depth: number; height: number };
  walls: Wall[];
  openings: Opening[];
}

export interface ModuleDimensionsMm {
  w: number;
  h: number;
  d: number;
}

export type RotationDeg = 0 | 90 | 180 | 270;

export interface PlannerModule {
  id: string;
  productId: string;
  productVariationId: string | null;
  position: { x: number; y: number; z: number };
  rotationDeg: RotationDeg;
  dimensionsMm: ModuleDimensionsMm;
  meta: {
    name: string;
    colorHex: string | null;
  };
}
