import { saveCanvasToBackendWithWorker } from "../ts/zipper";

const workerUrl = new URL("./worker", import.meta.url);

declare global {
  interface Window {
    record: boolean;
  }
}

const canvas = document.createElement("canvas");
canvas.width = 6000;
canvas.height = 6000;
document.body.appendChild(canvas);

const ctx = canvas.getContext("2d");
let frame = 0;
let sequenceName = Date.now();

let rotation = 0;
let fps = 60;

const animate = () => {
  ctx.fillStyle = "black";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.save();
  ctx.fillStyle = "white";
  const rectSize = canvas.width * 0.75;
  ctx.translate(canvas.width / 2, canvas.height / 2);
  ctx.rotate(rotation);
  ctx.fillRect(0, 0, 10, rectSize);
  ctx.restore();

  if (window.record) {
    saveCanvasToBackendWithWorker(
      "http://127.0.0.1:8000/",
      "canvas",
      sequenceName.toString(),
      `${frame}`.padStart(3, 0),
      workerUrl,
    );
    frame++;
  }

  rotation += 1.0 / fps;

  if (!window.record) {
    requestAnimationFrame(animate);
    // setTimeout(() => animate(), (1.0 / fps) * 1000);
  } else {
    setTimeout(() => animate(), (1.0 / fps) * 1000);
  }
};

animate();

const recordButton = document.createElement("button");
recordButton.innerText = "Record";
recordButton.onclick = () => {
  window.record = !window.record;
  if (window.record) {
    frame = 0;
    sequenceName = Date.now();
  }
  recordButton.innerText = window.record ? "Stop" : "Record";
};
document.body.appendChild(recordButton);
