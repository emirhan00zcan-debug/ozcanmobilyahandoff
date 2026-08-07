import Link from "next/link";
import { FaDirections } from "react-icons/fa";
import ShowroomAppointmentModal from "./ShowroomAppointmentModal";

type Props = {
  title: string;
  address: string;
  lat: number;
  lon: number;
};

// Harita için Google/Mapbox API anahtarı gerektirmeyen OpenStreetMap embed'i —
// bbox koordinatın etrafında sabit bir marj (~600m) ile hesaplanıyor.
function buildOsmEmbedSrc(lat: number, lon: number) {
  const delta = { lat: 0.004, lon: 0.006 };
  const bbox = [lon - delta.lon, lat - delta.lat, lon + delta.lon, lat + delta.lat].join(",");
  return `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat},${lon}`;
}

export default function LocationMapCard({ title, address, lat, lon }: Props) {
  return (
    <div className="overflow-hidden rounded-2xl border border-secondary/10">
      <div className="aspect-[4/3] w-full">
        <iframe
          src={buildOsmEmbedSrc(lat, lon)}
          title={`${title} konum haritası`}
          loading="lazy"
          className="h-full w-full border-0"
        />
      </div>
      <div className="p-5">
        <p className="font-display text-base font-semibold text-secondary">{title}</p>
        <p className="mt-1 font-body text-sm leading-relaxed text-secondary-light">{address}</p>
        <div className="mt-3 flex items-center justify-between">
          <Link
            href={`https://www.google.com/maps/dir/?api=1&destination=${lat},${lon}`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 font-body text-xs font-semibold text-primary hover:underline"
          >
            <FaDirections className="h-3.5 w-3.5" />
            Yol Tarifi Al
          </Link>

          {title.toLowerCase() === "showroom" && (
            <ShowroomAppointmentModal />
          )}
        </div>
      </div>
    </div>
  );
}
