import { FaComments, FaPhone, FaPaperPlane, FaMapMarkerAlt } from "react-icons/fa";

type Props = { items: { label: string; value: string }[] };

const ICONS = [FaComments, FaPhone, FaPaperPlane, FaMapMarkerAlt];

export default function ContactInfoBar({ items }: Props) {
  return (
    <section className="border-y border-secondary/10">
      <div className="mx-auto grid max-w-7xl grid-cols-1 gap-6 px-4 py-8 sm:grid-cols-2 sm:px-6 lg:grid-cols-4 lg:divide-x lg:divide-secondary/10 lg:px-8">
        {items.map((item, i) => {
          const Icon = ICONS[i % ICONS.length];
          return (
            <div key={item.label} className="flex items-start gap-3 lg:pl-6 lg:first:pl-0">
              <Icon className="mt-0.5 h-5 w-5 shrink-0 text-primary" />
              <div>
                <p className="font-body text-sm font-semibold text-secondary">{item.label}</p>
                <p className="mt-0.5 font-body text-xs text-secondary-light">{item.value}</p>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
