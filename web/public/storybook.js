// TRMNL device screen dimensions per layout size (px).
const DIMENSIONS = {
  full: [800, 480],
  half_horizontal: [800, 240],
  half_vertical: [400, 480],
  quadrant: [400, 240],
};

const state = { name: null, size: null };
const preview = document.getElementById('preview');
const dataBox = document.getElementById('data');
const sizesBox = document.getElementById('sizes');
const titleBox = document.getElementById('title');

function renderFrame() {
  let data;
  try { data = JSON.parse(dataBox.value); } catch { return; }
  fetch(`/c/${state.name}/${state.size}/render`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data)
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

function selectComponent(button) {
  document.querySelectorAll('.nav-item').forEach((b) => b.classList.remove('active'));
  button.classList.add('active');
  state.name = button.dataset.name;
  titleBox.textContent = button.textContent.trim();
  dataBox.value = JSON.stringify(JSON.parse(button.dataset.sample), null, 2);

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

document.querySelectorAll('.nav-item').forEach((b) => b.addEventListener('click', () => selectComponent(b)));
dataBox.addEventListener('input', renderFrame);
document.getElementById('copy').addEventListener('click', () => {
  navigator.clipboard.writeText(window.MARKUP[state.name]);
});

const first = document.querySelector('.nav-item');
if (first) selectComponent(first);
