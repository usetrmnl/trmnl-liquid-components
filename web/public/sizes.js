// TRMNL screen dimensions per device and layout size (px); mashup sizes are halves/quarters of each device's own screen, not always OG's.
window.DIMENSIONS_BY_DEVICE = {
  og: {
    full: [800, 480],
    half_horizontal: [800, 240],
    half_vertical: [400, 480],
    quadrant: [400, 240],
  },
  x: {
    full: [1872, 1404],
    half_horizontal: [1872, 702],
    half_vertical: [936, 1404],
    quadrant: [936, 702],
  },
};

// The dev storybook and playground only ever preview OG.
window.DIMENSIONS = window.DIMENSIONS_BY_DEVICE.og;
