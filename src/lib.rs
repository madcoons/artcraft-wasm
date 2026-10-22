//! A PhotoCraft session in the browser: open a file from its bytes, run any engine
//! command by id, and get the active document's composite.

use photocraft_engine::{Session, file_cmds};
use serde_json::json;
use wasm_bindgen::prelude::*;

fn err(e: impl std::fmt::Display) -> JsError {
    JsError::new(&e.to_string())
}

#[wasm_bindgen]
pub struct Editor {
    s: Session,
    /// The last `render`, owned here so JS can read it in place.
    frame: Vec<u8>,
}

#[wasm_bindgen]
impl Editor {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Editor {
        Editor { s: Session::new(), frame: Vec::new() }
    }

    /// Opens a file and makes it the active document. It's decoded by `name`'s extension, or by
    /// `ext` when given. Returns `{ document, color, warnings }`.
    #[wasm_bindgen(js_name = openBytesAs)]
    pub fn open_bytes_as(&mut self, name: &str, bytes: &[u8], ext: Option<String>) -> Result<JsValue, JsError> {
        to_js(&file_cmds::open_bytes_as(&mut self.s, name, bytes, ext.as_deref(), None).map_err(err)?)
    }

    /// Runs an engine command by id, e.g. `execute("image.imageSize", { width: 1600 })`.
    pub fn execute(&mut self, id: &str, params: JsValue) -> Result<JsValue, JsError> {
        let params = if params.is_undefined() { "{}".into() } else { String::from(js_sys::JSON::stringify(&params).map_err(|_| err("params are not JSON"))?) };
        to_js(&self.s.execute(id, serde_json::from_str(&params)?).map_err(err)?)
    }

    /// Composites the active document into the frame, straight RGBA8. Returns `{ width, height }`.
    // shortcut: values go out unconverted, right for sRGB documents only; CMYK or other profiles
    // need photocraft_engine::display_color, once a caller has such documents.
    pub fn render(&mut self) -> Result<JsValue, JsError> {
        let doc = &self.s.active().ok_or_else(|| err("no document"))?.doc;
        let img = photocraft_compose::flatten(doc).to_rgba8();
        self.frame = img.pixels;
        to_js(&json!({ "width": img.width, "height": img.height }))
    }

    /// Where the last frame starts in wasm memory, for a view on it without a copy. It stays put
    /// until the next `render`, but a view must be made after every call: growing the memory
    /// detaches its old buffer.
    #[wasm_bindgen(js_name = framePtr)]
    pub fn frame_ptr(&self) -> *const u8 {
        self.frame.as_ptr()
    }

    #[wasm_bindgen(js_name = frameLen)]
    pub fn frame_len(&self) -> usize {
        self.frame.len()
    }
}

fn to_js(v: &serde_json::Value) -> Result<JsValue, JsError> {
    js_sys::JSON::parse(&v.to_string()).map_err(|_| err("result is not JSON"))
}
