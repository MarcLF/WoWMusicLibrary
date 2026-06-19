local WML = WoWMusicLibrary

WML.Data = WML.Data or {}

WML.Data.Playlists = {
    {
        id = "official-kalimdor",
        name = "Kalimdor",
        official = true,
        description = "Zone music from Kalimdor.",
        tracks = {
            "kalimdor-barrens-day-1",
            "kalimdor-barrens-night-1",
            "kalimdor-mulgore-day-1",
            "kalimdor-tanaris-day-1",
            "kalimdor-ashenvale-forest-1",
            "kalimdor-ungoro-day-1",
        },
    },
    {
        id = "official-eastern-kingdoms",
        name = "Eastern Kingdoms",
        official = true,
        description = "Zone music from Eastern Kingdoms.",
        tracks = {
            "eastern-elwynn-day-1",
            "eastern-elwynn-night-1",
            "eastern-duskwood-day-1",
            "eastern-stranglethorn-night-1",
            "eastern-dun-morogh-day-1",
            "eastern-blasted-lands-1",
        },
    },
}
