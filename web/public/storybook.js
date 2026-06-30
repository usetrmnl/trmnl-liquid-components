// TRMNL device screen dimensions per layout size (px).
const DIMENSIONS = {
  full: [800, 480],
  half_horizontal: [800, 240],
  half_vertical: [400, 480],
  quadrant: [400, 240],
};

const state = { name: null, size: null, options: {} };
const preview = document.getElementById('preview');
const dataBox = document.getElementById('data');
const sizesBox = document.getElementById('sizes');
const titleBox = document.getElementById('title');
const controlsBox = document.getElementById('controls');

function renderFrame() {
  let data;
  try { data = JSON.parse(dataBox.value); } catch { return; }
  fetch(`/c/${state.name}/${state.size}/render`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ data, options: state.options }),
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

// Build the options/controls panel ("args") from a component's option specs.
function buildControls(options) {
  controlsBox.innerHTML = '';
  state.options = {};
  options.forEach((opt) => {
    state.options[opt.key] = String(opt.default);
    const wrap = document.createElement('label');
    wrap.className = 'control';
    wrap.append(Object.assign(document.createElement('span'), { textContent: opt.label || opt.key }));

    let input;
    if (opt.type === 'boolean') {
      input = document.createElement('input');
      input.type = 'checkbox';
      input.checked = String(opt.default) === 'yes';
      input.addEventListener('change', () => { state.options[opt.key] = input.checked ? 'yes' : 'no'; renderFrame(); });
    } else if (opt.type === 'select') {
      input = document.createElement('select');
      (opt.choices || []).forEach((choice) => {
        const o = document.createElement('option');
        o.value = String(choice); o.textContent = String(choice);
        if (String(choice) === String(opt.default)) o.selected = true;
        input.appendChild(o);
      });
      input.addEventListener('change', () => { state.options[opt.key] = input.value; renderFrame(); });
    } else {
      input = document.createElement('input');
      input.type = opt.type === 'number' ? 'number' : 'text';
      input.value = String(opt.default ?? '');
      input.addEventListener('input', () => { state.options[opt.key] = input.value; renderFrame(); });
    }
    wrap.appendChild(input);
    controlsBox.appendChild(wrap);
  });
}

function selectComponent(button) {
  document.querySelectorAll('.nav-item').forEach((b) => b.classList.remove('active'));
  button.classList.add('active');
  state.name = button.dataset.name;
  titleBox.textContent = button.textContent.trim();
  dataBox.value = JSON.stringify(JSON.parse(button.dataset.sample), null, 2);
  buildControls(JSON.parse(button.dataset.options || '[]'));

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
