# Этап 2 — туннель внутри приложения (NetworkExtension)

Сейчас XOLIRX iOS — менеджер: он готовит подписку и конфиг и открывает
установленный клиент (sing-box / Streisand / Shadowrocket). Такой вариант
собирается и ставится с бесплатным Apple ID.

Собственный туннель требует `NEPacketTunnelProvider` и встроенного ядра.
Это отдельный target, платный Apple Developer аккаунт и entitlement
`com.apple.developer.networking.networkextension`. Ниже — честный план без
«магии»: никакой код из этого файла не компилируется в текущей сборке.

## Что понадобится

1. **Платный Apple Developer Program** ($99/год). Бесплатный Apple ID
   не выдаёт entitlement для NetworkExtension — подпись с ним не пройдёт.
2. **App Group** `group.org.xolirx.vpn` — общий контейнер для конфига:
   приложение пишет `config.json`, расширение читает.
3. **Встроенное ядро.** Два реальных пути:
   - `sing-box` + `libbox` (Swift Package / XCFramework, официальные релизы
     SagerNet) — рекомендуется, у вас уже есть sing-box-конфиги;
   - Xray-core как XCFramework — больше кода-обвязки на C/Go.
4. **Capabilities** у обоих target:
   - App: App Groups;
   - Extension: App Groups + Network Extensions → Packet Tunnel.

## Файлы в этой папке

| Файл | Назначение |
| --- | --- |
| `Xolirx.entitlements` | App Group для основного приложения |
| `Tunnel.entitlements` | App Group + NetworkExtension для расширения |
| `TunnelProvider.swift.sample` | скелет провайдера (не входит в сборку) |
| `project-tunnel.yml` | фрагмент для `project.yml` (не подключён) |

Файлы специально **не** подключены к `project.yml`: с ними сборка
неподписанного IPA и подпись бесплатным Apple ID перестанут работать.

## Порядок работ

1. Получить платный аккаунт, создать App ID `org.xolirx.vpn` и
   `org.xolirx.vpn.tunnel`, включить App Groups и Network Extensions.
2. Добавить в `project.yml` target типа `app-extension`
   (`com.apple.network-extension`), встроить его в приложение.
3. Скопировать `TunnelProvider.swift.sample` → `Tunnel/TunnelProvider.swift`,
   подключить `libbox` и заменить `TODO` на старт ядра с конфигом из
   App Group. Провайдер должен вызвать `setTunnelNetworkSettings` с
   IPv4-адресом, DNS и MTU 9000/1500 — до `completionHandler(nil)`.
4. В приложении: `NETunnelProviderManager`, `loadAllFromPreferences`,
   `saveToPreferences`, затем `startVPNTunnel()`. Статус показывать по
   `NEVPNStatusDidChange`, а не «на глаз».
5. Проверить: `xcrun devicectl` / Xcode → Device, затем реальное
   переключение IP и разрыв соединения (kill switch на iOS —
   `includeAllNetworks` в `NEVPNProtocol`).
6. Только после этого менять формулировки в UI с «открыть в клиенте»
   на «подключить».

## Ограничения, которые не обойти

- NetworkExtension-приложение нельзя собрать на Windows и нельзя
  подписать бесплатным Apple ID.
- App Store-ревью для VPN строже: нужны политика конфиденциальности,
  отсутствие «серых» схем и подтверждение права работать с сетью.
- IP-адрес и статистика трафика внутри туннеля доступны только ядру;
  пинг до узла без поднятого туннеля остаётся TCP-хендшейком.
