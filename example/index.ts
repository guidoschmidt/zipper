import { saveCanvasToBackend } from "../ts/zipper";

declare global {
  interface Window {
    record: boolean;
  }
}

const canvas = document.createElement("canvas");
canvas.width = 1080;
canvas.height = 1080;
document.body.appendChild(canvas);

const ctx = canvas.getContext("2d");
let frame = 0;

window.record = true;

const animate = async (t: number) => {
  ctx.fillStyle = "black";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.save();
  ctx.fillStyle = "white";
  const rectSize = 100;
  ctx.translate(
    canvas.width / 2 - rectSize / 2,
    canvas.height / 2 - rectSize / 2,
  );
  ctx.rotate(t * 0.001);
  ctx.fillRect(-rectSize / 2, -rectSize / 2, rectSize, rectSize);
  ctx.restore();

  requestAnimationFrame(animate);

  if (window.record)
    await saveCanvasToBackend(
      "http://127.0.0.1:8000/",
      "canvas",
      "test",
      frame,
    );
  frame++;
};

animate(0);
