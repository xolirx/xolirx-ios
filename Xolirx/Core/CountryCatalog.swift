import Foundation

/// Определение страны по названию узла.
/// Поддерживает эмодзи-флаги, коды в скобках («[US] New York»), нумерованные
/// коды («NL-01», «FI15»), английские и русские названия, а также города.
enum CountryCatalog {

    static let names: [String: String] = [
        "швеция": "SE", "sweden": "SE", "стокгольм": "SE", "stockholm": "SE",
        "финляндия": "FI", "finland": "FI", "хельсинки": "FI", "helsinki": "FI",
        "испания": "ES", "spain": "ES", "мадрид": "ES", "madrid": "ES", "барселона": "ES", "barcelona": "ES",
        "германия": "DE", "germany": "DE", "франкфурт": "DE", "frankfurt": "DE", "берлин": "DE", "berlin": "DE",
        "нидерланды": "NL", "netherlands": "NL", "holland": "NL", "амстердам": "NL", "amsterdam": "NL",
        "сша": "US", "usa": "US", "america": "US", "америка": "US", "new york": "US", "нью-йорк": "US",
        "великобритания": "GB", "britain": "GB", "england": "GB", "англия": "GB", "london": "GB", "лондон": "GB",
        "франция": "FR", "france": "FR", "париж": "FR", "paris": "FR",
        "италия": "IT", "italy": "IT", "милан": "IT", "milan": "IT", "рим": "IT", "rome": "IT",
        "норвегия": "NO", "norway": "NO", "осло": "NO", "oslo": "NO",
        "дания": "DK", "denmark": "DK", "копенгаген": "DK", "copenhagen": "DK",
        "индия": "IN", "india": "IN", "мумбаи": "IN", "mumbai": "IN",
        "япония": "JP", "japan": "JP", "токио": "JP", "tokyo": "JP",
        "турция": "TR", "turkey": "TR", "стамбул": "TR", "istanbul": "TR",
        "польша": "PL", "poland": "PL", "варшава": "PL", "warsaw": "PL",
        "чехия": "CZ", "czechia": "CZ", "прага": "CZ", "prague": "CZ",
        "австрия": "AT", "austria": "AT", "вена": "AT", "vienna": "AT",
        "швейцария": "CH", "switzerland": "CH", "цюрих": "CH", "zurich": "CH",
        "канада": "CA", "canada": "CA", "торонто": "CA", "toronto": "CA",
        "бразилия": "BR", "brazil": "BR", "сан-паулу": "BR", "sao paulo": "BR",
        "австралия": "AU", "australia": "AU", "сидней": "AU", "sydney": "AU",
        "сингапур": "SG", "singapore": "SG",
        "гонконг": "HK", "hong kong": "HK",
        "корея": "KR", "korea": "KR", "сеул": "KR", "seoul": "KR",
        "китай": "CN", "china": "CN", "пекин": "CN", "beijing": "CN",
        "украина": "UA", "ukraine": "UA", "киев": "UA", "kyiv": "UA",
        "казахстан": "KZ", "kazakhstan": "KZ", "алматы": "KZ", "almaty": "KZ",
        "эстония": "EE", "estonia": "EE", "таллин": "EE", "tallinn": "EE",
        "латвия": "LV", "latvia": "LV", "рига": "LV", "riga": "LV",
        "литва": "LT", "lithuania": "LT", "вильнюс": "LT", "vilnius": "LT",
        "ирландия": "IE", "ireland": "IE", "дублин": "IE", "dublin": "IE",
        "португалия": "PT", "portugal": "PT", "лиссабон": "PT", "lisbon": "PT",
        "румыния": "RO", "romania": "RO", "бухарест": "RO", "bucharest": "RO",
        "болгария": "BG", "bulgaria": "BG", "софия": "BG", "sofia": "BG",
        "венгрия": "HU", "hungary": "HU", "будапешт": "HU", "budapest": "HU",
        "греция": "GR", "greece": "GR", "афины": "GR", "athens": "GR",
        "сербия": "RS", "serbia": "RS", "белград": "RS", "belgrade": "RS",
        "хорватия": "HR", "croatia": "HR", "загреб": "HR", "zagreb": "HR",
        "словакия": "SK", "slovakia": "SK", "братислава": "SK", "bratislava": "SK",
        "словения": "SI", "slovenia": "SI", "любляна": "SI", "ljubljana": "SI",
        "молдова": "MD", "moldova": "MD", "кишинёв": "MD", "chisinau": "MD",
        "грузия": "GE", "georgia country": "GE", "тбилиси": "GE", "tbilisi": "GE",
        "армения": "AM", "armenia": "AM", "ереван": "AM", "yerevan": "AM",
        "азербайджан": "AZ", "azerbaijan": "AZ", "баку": "AZ", "baku": "AZ",
        "узбекистан": "UZ", "uzbekistan": "UZ", "ташкент": "UZ", "tashkent": "UZ",
        "израиль": "IL", "israel": "IL", "тель-авив": "IL", "tel aviv": "IL",
        "эмираты": "AE", "uae": "AE", "dubai": "AE", "дубай": "AE",
        "саудовская аравия": "SA", "saudi": "SA",
        "юар": "ZA", "south africa": "ZA", "johannesburg": "ZA",
        "аргентина": "AR", "argentina": "AR", "буэнос-айрес": "AR", "buenos aires": "AR",
        "чили": "CL", "chile": "CL", "сантьяго": "CL", "santiago": "CL",
        "мексика": "MX", "mexico": "MX", "мехико": "MX", "mexico city": "MX",
        "колумбия": "CO", "colombia": "CO", "богота": "CO", "bogota": "CO",
        "перу": "PE", "peru": "PE", "лима": "PE", "lima": "PE",
        "исландия": "IS", "iceland": "IS", "рейкьявик": "IS", "reykjavik": "IS",
        "люксембург": "LU", "luxembourg": "LU",
        "мальта": "MT", "malta": "MT",
        "кипр": "CY", "cyprus": "CY",
        "албания": "AL", "albania": "AL",
        "македония": "MK", "macedonia": "MK",
        "босния": "BA", "bosnia": "BA",
        "черногория": "ME", "montenegro": "ME",
        "беларусь": "BY", "belarus": "BY", "минск": "BY", "minsk": "BY",
        "таиланд": "TH", "thailand": "TH", "банкок": "TH", "bangkok": "TH",
        "вьетнам": "VN", "vietnam": "VN", "ханой": "VN", "hanoi": "VN",
        "малайзия": "MY", "malaysia": "MY", "куала-лумпур": "MY", "kuala lumpur": "MY",
        "индонезия": "ID", "indonesia": "ID", "джакарта": "ID", "jakarta": "ID",
        "филиппины": "PH", "philippines": "PH", "манила": "PH", "manila": "PH",
        "тайвань": "TW", "taiwan": "TW", "тайбэй": "TW", "taipei": "TW",
        "новая зеландия": "NZ", "new zealand": "NZ", "окленд": "NZ", "auckland": "NZ",
        "египет": "EG", "egypt": "EG", "каир": "EG", "cairo": "EG",
        "марокко": "MA", "morocco": "MA",
        "нигерия": "NG", "nigeria": "NG",
        "кения": "KE", "kenya": "KE",
        "пакистан": "PK", "pakistan": "PK",
        "бангладеш": "BD", "bangladesh": "BD",
        "шри-ланка": "LK", "sri lanka": "LK",
        "непал": "NP", "nepal": "NP",
        "катар": "QA", "qatar": "QA",
        "кувейт": "KW", "kuwait": "KW",
        "бахрейн": "BH", "bahrain": "BH",
        "оман": "OM", "oman": "OM",
        "иордания": "JO", "jordan": "JO",
        "ливан": "LB", "lebanon": "LB",
        "ирак": "IQ", "iraq": "IQ",
        "иран": "IR", "iran": "IR",
        "афганистан": "AF", "afghanistan": "AF",
        "монголия": "MN", "mongolia": "MN",
        "мьянма": "MM", "myanmar": "MM",
        "камбоджа": "KH", "cambodia": "KH",
        "лаос": "LA", "laos": "LA",
        "бруней": "BN", "brunei": "BN",
        "мальдивы": "MV", "maldives": "MV",
        "россия": "RU", "russia": "RU", "москва": "RU", "moscow": "RU",
        "петербург": "RU", "saint petersburg": "RU"
    ]

    static let iso: Set<String> = Set(names.values)

    /// Слова, которые похожи на ISO-коды, но страной не являются.
    private static let stopwords: Set<String> = [
        "IT", "IN", "NO", "IS", "ME", "AT", "BE", "TO", "SO", "DO", "GO",
        "MY", "US", "TV", "ON", "UP", "BY", "OF", "OR", "AS", "ID"
    ]

    static func code(for raw: String) -> String {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "" }
        let lower = name.lowercased()

        if let emoji = emojiCode(name) { return emoji }
        if let bracket = bracketCode(name) { return bracket }

        // Узел назван ровно кодом страны: «US», «NL», «IT».
        if name.count == 2 {
            let direct = name.uppercased()
            if iso.contains(direct) { return direct }
        }

        for token in tokens(lower) {
            let upper = token.uppercased()
            if upper.count > 2 {
                let prefix = String(upper.prefix(2))
                let rest = upper.dropFirst(2)
                // «NO-01», «IT15», «US_2»: цифровой хвост снимает неоднозначность
                // служебных слов, поэтому stopwords здесь не мешают.
                if iso.contains(prefix),
                   rest.allSatisfy({ $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." }) {
                    return prefix
                }
            }
            if upper.count == 2, iso.contains(upper), !stopwords.contains(upper) {
                return upper
            }
        }

        for (word, code) in names.sorted(by: { $0.key.count > $1.key.count }) where lower.contains(word) {
            return code
        }
        return ""
    }

    private static func tokens(_ s: String) -> [String] {
        s.split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" && $0 != "_" })
            .map(String.init)
    }

    private static func emojiCode(_ s: String) -> String? {
        var scalars: [UnicodeScalar] = []
        for u in s.unicodeScalars {
            if (0x1F1E6...0x1F1FF).contains(u.value) {
                guard let letter = UnicodeScalar(u.value - 0x1F1E6 + 65) else { return nil }
                scalars.append(letter)
                if scalars.count == 2 { break }
            }
        }
        guard scalars.count == 2 else { return nil }
        return String(scalars.map { Character($0) })
    }

    private static func bracketCode(_ s: String) -> String? {
        let chars = Array(s)
        var i = 0
        while i < chars.count - 3 {
            let open = chars[i]
            if open == "[" || open == "(" {
                let close: Character = open == "[" ? "]" : ")"
                let a = chars[i + 1], b = chars[i + 2]
                if chars[i + 3] == close, a.isLetter, b.isLetter {
                    let code = String([a, b]).uppercased()
                    if iso.contains(code) { return code }
                }
            }
            i += 1
        }
        return nil
    }
}
