const preview = document.getElementById('preview');
const navBox = document.getElementById('nav');
const sizesBox = document.getElementById('sizes');
const variantsBox = document.getElementById('variants');
const titleBox = document.getElementById('title');
const usageBox = document.getElementById('usage');
const bundleBox = document.getElementById('bundle');
const devicesBox = document.getElementById('devices');
const state = { component: null, size: null, variant: null, device: window.DEVICES[0].name };

function applyDimensions(size) {
  const dimensions = window.DIMENSIONS_BY_DEVICE[state.device];
  const [width, height] = dimensions[size] || dimensions.full;
  preview.style.width = `${width}px`;
  preview.style.height = `${height}px`;

  // Render at the device's true resolution, then scale the frame down to fit the
  // preview area (never up) so a large screen like TRMNL X does not overflow.
  const wrap = preview.closest('.preview-wrap');
  const pad = 32;
  const scale = Math.min(1, (wrap.clientWidth - pad) / width, (wrap.clientHeight - pad) / height);
  preview.style.transform = `scale(${scale})`;
  preview.style.transformOrigin = 'top left';

  const box = document.getElementById('preview-scale');
  box.style.width = `${width * scale}px`;
  box.style.height = `${height * scale}px`;
}

window.addEventListener('resize', () => { if (state.size) applyDimensions(state.size); });

function refresh() {
  applyDimensions(state.size);
  preview.src = `c/${state.component.name}/${state.variant}/${state.device}/${state.size}.html`;
}

function pickerButtons(box, items, activeValue, onPick) {
  box.innerHTML = '';
  if (items.length < 2) return;
  items.forEach((item) => {
    const button = document.createElement('button');
    button.textContent = item.label;
    button.classList.toggle('active', item.value === activeValue);
    button.addEventListener('click', () => {
      onPick(item.value);
      box.querySelectorAll('button').forEach((x) => x.classList.toggle('active', x === button));
      refresh();
    });
    box.appendChild(button);
  });
}

function selectComponent(component, link) {
  navBox.querySelectorAll('a').forEach((x) => x.classList.toggle('active', x === link));
  state.component = component;
  state.size = component.sizes[0];
  state.variant = component.variants[0].slug;
  titleBox.textContent = component.title;
  usageBox.textContent = component.usage;
  bundleBox.textContent = component.bundle;
  pickerButtons(devicesBox, window.DEVICES.map((d) => ({ label: d.label, value: d.name })), state.device, (v) => { state.device = v; });
  pickerButtons(sizesBox, component.sizes.map((s) => ({ label: s, value: s })), state.size, (v) => { state.size = v; });
  pickerButtons(variantsBox, component.variants.map((v) => ({ label: v.name, value: v.slug })), state.variant, (v) => { state.variant = v; });
  refresh();
}

let firstLink = null;
let firstComponent = null;
Object.entries(window.CATALOG).forEach(([category, components]) => {
  navBox.appendChild(Object.assign(document.createElement('h3'), { textContent: category }));
  components.forEach((component) => {
    const link = document.createElement('a');
    link.className = 'nav-item';
    link.href = '#';
    link.textContent = component.title;
    link.title = component.description || '';
    link.addEventListener('click', (event) => { event.preventDefault(); selectComponent(component, link); });
    navBox.appendChild(link);
    if (!firstLink) { firstLink = link; firstComponent = component; }
  });
});

document.querySelectorAll('button.copy').forEach((button) => {
  button.addEventListener('click', () => {
    navigator.clipboard.writeText(state.component[button.dataset.copies]);
    button.textContent = 'Copied';
    setTimeout(() => { button.textContent = 'Copy'; }, 1200);
  });
});

if (firstLink) selectComponent(firstComponent, firstLink);
