if not StrategosBattlegound_Localizations then
    StrategosBattlegound_Localizations = {}
end

-- ↑ABOVE LINES HAVE TO BE INCLUDED AT THE BEGINNING OF EACH LOCALIZATION FILES↑
-- ADDING A NEW LOCALIZATION:
-- To add a new localization create a new file using this as a model, just replace `enUS`
-- with your language in `StrategosBattlegound_Localizations.enUS` (e.g. `StrategosBattlegound_Localizations.itIT`) and change
-- and replace the strings having care of leaving words followed by a `%` as they are
-- (e.g. `ARATHI_BOARD_WINNING_FACTION = "Horde wins in: %time"` ->
--       `ARATHI_BOARD_WINNING_FACTION = "L'Orda vincerà in: %time"`)
-- Remember to add the name of your file at the end of the .toc file.

StrategosBattlegound_Localizations.enUS = {
    WARSONG_FLAG_GROUND = "GROUND",
    ARATHI_BOARD_STALL = "Stalling",
    ARATHI_BOARD_WINNING_FACTION0 = "Horde wins in: %time",
    ARATHI_BOARD_WINNING_FACTION1 = "Alliance wins in: %time",
    ARATHI_BOARD_WIN_FACTION0 = "Horde wins!",
    ARATHI_BOARD_WIN_FACTION1 = "Alliance wins!",
    WARSONG_LOWHEALTH_CHAT_WARN0 = "\124cffff0000\124Hplayer:%pname\124h[Horde Flag Carrier]\124h\124r is below %health% Health!",
    WARSONG_LOWHEALTH_CHAT_WARN1 = "\124cff00b0ff\124Hplayer:%pname\124h[Alliance Flag Carrier]\124h\124r is below %health% Health!",
    BG_START_IN_CHAT = "Starting in: %time",
    BG_START_IN_UI = "[BG] Starting in"
}
