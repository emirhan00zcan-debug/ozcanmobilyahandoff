declare namespace JSX {
    interface IntrinsicElements {
        "model-viewer": React.DetailedHTMLProps<
            React.HTMLAttributes<HTMLElement> & {
                src?: string;
                "ios-src"?: string;
                alt?: string;
                ar?: boolean;
                "ar-modes"?: string;
                "camera-controls"?: boolean;
                "touch-action"?: string;
                "shadow-intensity"?: string;
                "shadow-softness"?: string;
                "ar-scale"?: string;
                class?: string;
            },
            HTMLElement
        >;
    }
}
