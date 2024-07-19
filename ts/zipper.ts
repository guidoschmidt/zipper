export async function saveCanvasToBackend(
  zipperUrl: string,
  selector: string,
  sequence: string,
  frame: number,
) {
  const canvas: HTMLCanvasElement | null = document.querySelector(
    selector || "canvas",
  );
  if (canvas === null) {
    throw new Error(`No canvas element with ${selector} found`);
  }
  const dataUrl = canvas!.toDataURL("image/png");
  const data = {
    imageData: dataUrl,
    foldername: `${sequence}`,
    filename: `${frame}`,
    ext: "png",
  };
  await fetch(zipperUrl, {
    method: "POST",
    body: JSON.stringify(data),
  });
}
