--
-- Formspec elements list. Do not update this by hand, it is auto-generated
-- by make_elements.py.
--

local a = {}
a[1] = {"w", "number"}
a[2] = {"h", "number"}
a[3] = {a[1], a[2]}
a[4] = {{"x", "number"}, {"y", "number"}}
a[5] = {{a[4]}}
a[6] = {}
a[7] = {a[6]}
a[8] = {"scrollbar_name", "string"}
a[9] = {"orientation", "string"}
a[10] = {"inventory_location", "string"}
a[11] = {"list_name", "string"}
a[12] = {"slot_bg_normal", "string"}
a[13] = {"slot_bg_hover", "string"}
a[14] = {"slot_border", "string"}
a[15] = {"tooltip_text", "string"}
a[16] = {"bgcolor", "string"}
a[17] = {"fontcolor", "string"}
a[18] = {"gui_element_name", "string"}
a[19] = {"texture_name", "string"}
a[20] = {a[4], a[3], a[19]}
a[21] = {"name", "string"}
a[22] = {"frame_count", "number"}
a[23] = {"frame_duration", "number"}
a[24] = {"mesh", "string"}
a[25] = {{{"textures", "string"}, "..."}}
a[26] = {{"rotation_x", "number"}, {"rotation_y", "number"}}
a[27] = {"continuous", "boolean"}
a[28] = {"mouse_control", "boolean"}
a[29] = {{"frame_loop_begin", "number"}, {"frame_loop_end", "number"}}
a[30] = {"item_name", "string"}
a[31] = {"fullscreen", "fullscreen"}
a[32] = {"auto_clip", "boolean"}
a[33] = {"middle_x", "number"}
a[34] = {"middle_y", "number"}
a[35] = {"label", "string"}
a[36] = {{a[4], a[3], a[21], a[35]}}
a[37] = {"default", "string"}
a[38] = {a[4], a[3], a[21], a[35], a[37]}
a[39] = {{a[4], a[35]}}
a[40] = {a[4], a[3], a[19], a[21], a[35]}
a[41] = {{{"listelem", "string"}, "..."}}
a[42] = {"selected_idx", "number"}
a[43] = {"transparent", "boolean"}
a[44] = {{{"caption", "string"}, "..."}}
a[45] = {"current_tab", "string"}
a[46] = {"draw_border", "boolean"}
a[47] = {{{"item", "string"}, "..."}}
a[48] = {"index_event", "boolean"}
a[49] = {{"opt", "table"}, "..."}
a[50] = {{a[49]}}
a[51] = {{"prop", "table"}, "..."}
a[52] = {a[21]}
a[53] = {{{{{"selectors", "string"}, "..."}}, a[51]}, {a[52], a[51]}}
return {["formspec_version"] = {{{"version", "number"}}}, ["size"] = {{a[3]}, {{a[1], a[2], {"fixed_size", "boolean"}}}}, ["position"] = a[5], ["anchor"] = a[5], ["no_prepend"] = a[7], ["real_coordinates"] = {{{"bool", "boolean"}}}, ["container"] = a[5], ["container_end"] = a[7], ["scroll_container"] = {{a[4], a[3], a[8], a[9], {"scroll_factor", "number"}}, {a[4], a[3], a[8], a[9]}}, ["scroll_container_end"] = a[7], ["list"] = {{a[10], a[11], a[4], a[3], {"", "null"}}, {a[10], a[11], a[4], a[3], {"starting_item_index", "number"}}}, ["listring"] = {{a[10], a[11]}, a[6]}, ["listcolors"] = {{a[12], a[13], a[14], {"tooltip_bgcolor", "string"}, {"tooltip_fontcolor", "string"}}, {a[12], a[13], a[14]}, {a[12], a[13]}}, ["tooltip"] = {{a[4], a[3], a[15], a[16], a[17]}, {a[4], a[3], a[15], a[16]}, {a[18], a[15], a[16], a[17]}, {a[4], a[3], a[15]}, {a[18], a[15], a[16]}, {a[18], a[15]}}, ["image"] = {a[20]}, ["animated_image"] = {{a[4], a[3], a[21], a[19], a[22], a[23], {"frame_start", "number"}}, {a[4], a[3], a[21], a[19], a[22], a[23]}}, ["model"] = {{a[4], a[3], a[21], a[24], a[25], a[26], a[27], a[28], a[29], {"animation_speed", "number"}}, {a[4], a[3], a[21], a[24], a[25], a[26], a[27], a[28], a[29]}, {a[4], a[3], a[21], a[24], a[25], a[26], a[27], a[28]}, {a[4], a[3], a[21], a[24], a[25], a[26], a[27]}, {a[4], a[3], a[21], a[24], a[25], a[26]}, {a[4], a[3], a[21], a[24], a[25]}}, ["item_image"] = {{a[4], a[3], a[30]}}, ["bgcolor"] = {{a[16], a[31], {"fbgcolor", "string"}}, {a[16], a[31]}, {a[16]}}, ["background"] = {{a[4], a[3], a[19], a[32]}, a[20]}, ["background9"] = {{a[4], a[3], a[19], a[32], {a[33], a[34], {"middle_x2", "number"}, {"middle_y2", "number"}}}, {a[4], a[3], a[19], a[32], {a[33], a[34]}}, {a[4], a[3], a[19], a[32], {a[33]}}}, ["pwdfield"] = a[36], ["field"] = {a[38], {a[21], a[35], a[37]}}, ["field_close_on_enter"] = {{a[21], {"close_on_enter", "boolean"}}}, ["textarea"] = {a[38]}, ["label"] = a[39], ["hypertext"] = {{a[4], a[3], a[21], {"text", "string"}}}, ["vertlabel"] = a[39], ["button"] = a[36], ["image_button"] = {{a[4], a[3], a[19], a[21], a[35], {"noclip", "boolean"}, {"drawborder", "boolean"}, {"pressed_texture_name", "string"}}, a[40]}, ["item_image_button"] = {{a[4], a[3], a[30], a[21], a[35]}}, ["button_exit"] = a[36], ["image_button_exit"] = {a[40]}, ["textlist"] = {{a[4], a[3], a[21], a[41], a[42], a[43]}, {a[4], a[3], a[21], a[41], a[42]}, {a[4], a[3], a[21], a[41]}}, ["tabheader"] = {{a[4], a[2], a[21], a[44], a[45], a[43], a[46]}, {a[4], a[3], a[21], a[44], a[45], a[43], a[46]}, {a[4], a[21], a[44], a[45], a[43], a[46]}, {a[4], a[2], a[21], a[44], a[45], a[43]}, {a[4], a[3], a[21], a[44], a[45], a[43]}, {a[4], a[21], a[44], a[45], a[43]}, {a[4], a[2], a[21], a[44], a[45]}, {a[4], a[3], a[21], a[44], a[45]}, {a[4], a[21], a[44], a[45]}}, ["box"] = {{a[4], a[3], {"color", "string"}}}, ["dropdown"] = {{a[4], a[3], a[21], a[47], a[42], a[48]}, {a[4], a[1], a[21], a[47], a[42], a[48]}, {a[4], a[3], a[21], a[47], a[42]}, {a[4], a[1], a[21], a[47], a[42]}}, ["checkbox"] = {{a[4], a[21], a[35], {"selected", "boolean"}}, {a[4], a[21], a[35]}}, ["scrollbar"] = {{a[4], a[3], a[9], a[21], {"value", "string"}}}, ["scrollbaroptions"] = a[50], ["table"] = {{a[4], a[3], a[21], {{{"cells", "string"}, "..."}}, a[42]}}, ["tableoptions"] = a[50], ["tablecolumns"] = {{{{{"type", "string"}, a[49]}, "..."}}}, ["style"] = a[53], ["style_type"] = a[53], ["set_focus"] = {{a[21], {"force", "boolean"}}, a[52]}}
