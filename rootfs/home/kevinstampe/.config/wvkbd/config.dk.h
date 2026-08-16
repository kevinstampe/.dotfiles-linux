#ifndef config_h_INCLUDED
#define config_h_INCLUDED

#define DEFAULT_FONT "Sans 14"
#define DEFAULT_ROUNDING 5

/* Shift+space sends Tab. This layout has no Tab key, so keep it. */
#define SHIFT_SPACE_IS_TAB

static const int transparency = 255;

struct clr_scheme schemes[] = {
{
  /* scheme 0: normal keys */
  .bg = {.bgra = {15, 15, 15, transparency}},
  .fg = {.bgra = {45, 45, 45, transparency}},
  .high = {.bgra = {100, 100, 100, transparency}},
  .swipe = {.bgra = {100, 255, 100, 64}},
  .text = {.color = UINT32_MAX},
  .text_press = {.color = UINT32_MAX},
  .text_swipe = {.color = UINT32_MAX},
  .font = DEFAULT_FONT,
  .rounding = DEFAULT_ROUNDING,
},
{
  /* scheme 1: special keys (shift, backspace, layer switches, esc, enter) */
  .bg = {.bgra = {15, 15, 15, transparency}},
  .fg = {.bgra = {32, 32, 32, transparency}},
  .high = {.bgra = {100, 100, 100, transparency}},
  .swipe = {.bgra = {100, 255, 100, 64}},
  .text_press = {.color = UINT32_MAX},
  .text_swipe = {.color = UINT32_MAX},
  .text = {.color = UINT32_MAX},
  .font = DEFAULT_FONT,
  .rounding = DEFAULT_ROUNDING,
}
};

/* Layers are switched explicitly by the 123 / #+= / ABC keys, so these arrays
 * only decide the startup layout. Portrait and landscape are identical: the
 * folio-detached tablet is used in both orientations.
 */
static enum layout_id layers[] = {
  Letters, // First layout is the default layout on startup
  Numbers,
  Symbols,
  NumLayouts // signals the last item, may not be omitted
};

static enum layout_id landscape_layers[] = {
  Letters, // First layout is the default layout on startup
  Numbers,
  Symbols,
  NumLayouts // signals the last item, may not be omitted
};

#endif // config_h_INCLUDED
