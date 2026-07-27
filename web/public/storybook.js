// TRMNL device screen dimensions per layout size (px).
const DIMENSIONS = {
  full: [800, 480],
  half_horizontal: [800, 240],
  half_vertical: [400, 480],
  quadrant: [400, 240],
};

const state = { name: null, size: null, args: {}, markup: null };
const preview = document.getElementById('preview');
const dataBox = document.getElementById('data');
const markupBox = document.getElementById('markup');
const sizesBox = document.getElementById('sizes');
const titleBox = document.getElementById('title');
const variantsBox = document.getElementById('variants');

function renderFrame() {
  let data;
  try { data = JSON.parse(dataBox.value); } catch { return; }
  fetch(`/c/${state.name}/${state.size}/render`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ data, args: state.args, markup: state.markup }),
  }).then((r) => r.text()).then((html) => { preview.srcdoc = html; });
}

function applyDimensions(size) {
  const [w, h] = DIMENSIONS[size] || DIMENSIONS.full;
  preview.style.width = `${w}px`;
  preview.style.height = `${h}px`;
}

function selectSize(size, button) {
  state.size = size;
  applyDimensions(size);
  sizesBox.querySelectorAll('button').forEach((b) => b.classList.toggle('active', b === button));
  renderFrame();
}

function buildVariants(variants) {
  variantsBox.innerHTML = '';
  state.args = variants[0]?.args || {};
  if (variants.length < 2) return; // a lone Default variant is not worth a switcher
  variants.forEach((variant, i) => {
    const button = document.createElement('button');
    button.textContent = variant.name;
    button.addEventListener('click', () => {
      state.args = variant.args || {};
      variantsBox.querySelectorAll('button').forEach((x) => x.classList.toggle('active', x === button));
      renderFrame();
    });
    if (i === 0) button.classList.add('active');
    variantsBox.appendChild(button);
  });
}

function selectComponent(button) {
  document.querySelectorAll('button.nav-item').forEach((b) => b.classList.remove('active'));
  button.classList.add('active');
  state.name = button.dataset.name;
  titleBox.textContent = button.textContent.trim();
  dataBox.value = JSON.stringify(JSON.parse(button.dataset.sample), null, 2);
  markupBox.value = window.MARKUP[state.name] || '';
  state.markup = null; // null = render the on-disk markup until the user edits it
  buildVariants(JSON.parse(button.dataset.variants || '[]'));

  const sizes = button.dataset.sizes.split(',');
  sizesBox.innerHTML = '';
  sizes.forEach((s, i) => {
    const b = document.createElement('button');
    b.textContent = s;
    b.addEventListener('click', () => selectSize(s, b));
    if (i === 0) b.classList.add('active');
    sizesBox.appendChild(b);
  });
  state.size = sizes[0];
  applyDimensions(sizes[0]);
  renderFrame();
}

document.querySelectorAll('button.nav-item').forEach((b) => b.addEventListener('click', () => selectComponent(b)));
dataBox.addEventListener('input', renderFrame);
markupBox.addEventListener('input', () => { state.markup = markupBox.value; renderFrame(); });
document.getElementById('copy').addEventListener('click', () => {
  navigator.clipboard.writeText(markupBox.value);
});

const first = document.querySelector('button.nav-item');
if (first) selectComponent(first);
