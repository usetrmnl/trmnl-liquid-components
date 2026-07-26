const DIMENSIONS = {
  full: [800, 480],
  half_horizontal: [800, 240],
  half_vertical: [400, 480],
  quadrant: [400, 240],
};

const preview = document.getElementById('preview');
const dataBox = document.getElementById('data');
const markupBox = document.getElementById('markup');
const sizesBox = document.getElementById('sizes');
let size = 'full';

markupBox.value = window.SEED.markup;
dataBox.value = window.SEED.data;

function render() {
  let data;
  try { data = JSON.parse(dataBox.value); } catch { return; } // ignore mid-edit invalid JSON
  fetch(`/preview/${size}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ markup: markupBox.value, data }),
  }).then((r) => r.text()).then((html) => { preview.srcdoc = html; });
}

function applyDimensions(s) {
  const [w, h] = DIMENSIONS[s] || DIMENSIONS.full;
  preview.style.width = `${w}px`;
  preview.style.height = `${h}px`;
}

Object.keys(DIMENSIONS).forEach((s, i) => {
  const button = document.createElement('button');
  button.textContent = s;
  button.addEventListener('click', () => {
    size = s;
    applyDimensions(s);
    sizesBox.querySelectorAll('button').forEach((x) => x.classList.toggle('active', x === button));
    render();
  });
  if (i === 0) button.classList.add('active');
  sizesBox.appendChild(button);
});

dataBox.addEventListener('input', render);
markupBox.addEventListener('input', render);
document.getElementById('copy').addEventListener('click', () => navigator.clipboard.writeText(markupBox.value));

applyDimensions('full');
render();
