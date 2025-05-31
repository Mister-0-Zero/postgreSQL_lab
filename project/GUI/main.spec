# -*- mode: python ; coding: utf-8 -*-

from PyInstaller.utils.hooks import collect_all
import os

# Пути к файлам
base_dir = os.path.dirname(os.path.abspath('main.py'))
icon_path = os.path.join(base_dir, 'app_icon.ico')  # Путь к иконке

# Добавляем ресурсы
datas = [
    (os.path.join(base_dir, 'examples.md'), '.'),
    (os.path.join(base_dir, 'ERD.png'), '.'),
    (os.path.join(os.path.dirname(base_dir), 'README.md'), '.')
]

# Иконка (должна быть в формате .ico)
if os.path.exists(icon_path):
    icon = icon_path
else:
    icon = None
    print("Предупреждение: файл иконки не найден")

# Собираем зависимости Flet
flet_data = collect_all('flet')
datas += flet_data[0]
binaries = flet_data[1]
hiddenimports = flet_data[2]

a = Analysis(
    ['main.py'],
    pathex=[base_dir],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

# Настройки exe
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    name='CemeteryDB',  # Имя приложения (отобразится в заголовке)
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,  # Не показывать консольное окно
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=icon,  # Иконка приложения
)