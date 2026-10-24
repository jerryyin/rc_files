from system import Package

DEPENDENCIES = ('node', 'clangd')
PACKAGES = [
    Package('vim', ('vim',), 'vim.vim',
            arguments='/console=1 /desktop=0 /startmenu=0 /editwith=0 /vimrc=0 /launcher=0',
            search=('%ProgramFiles%/Vim/vim*/vim.exe', '%LOCALAPPDATA%/Programs/Vim/vim.exe'),
            exclude='/Git/'),
    Package('rg', winget='BurntSushi.ripgrep.MSVC'),
]
if PLATFORM == 'linux':
    PACKAGES += [Package('nvim', ('neovim',)),
                 Package(apt=('gcc', 'python3-dev', 'python3-setuptools', 'silversearcher-ag'))]
