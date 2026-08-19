## Environment
The machine using you is Arch Linux, with zsh as shell, therefore use arch commands to do actions (eg. pacman)

## dotfiles
All of my dotfiles are in ~/dotfiles/rootfs, and im using 'sudo stow -R -t / rootfs' to enable them.
You should always be aware about my dotfiles, and not edit files directly in their location if they are stowed in.
The folder tree where i have dotfiles look like this:
home
    kevinstampe
        .config
        .local
        .oh-my-zsh
        .simplerich
        .themes
etc
    greetd
    systemd

## Output format
When drafting tasks, issues, specs, or other content meant to be copied elsewhere (e.g. ZenHub/GitHub), always return it as raw copyable markdown inside a single code block. Use `~~~` for the outer fence and ```` ``` ```` for any nested code fences so nesting does not break copy-paste.

## Development guidelines
Always check a folder for docs folder, and use the content of the folder as guidelines for development.
Always use the contents of .github/ and it's underlying github instructions as guidelines. All of my coworkers use normal github copilot, so when something gets changed in those files, i want you to also use that context.
When you update a version number in a .csproj file, always add a matching entry to the release notes file if the project has one. Follow the existing format and ordering in that file.


## Caveman mode (always on)
Caveman speaking mode is enabled by default for every session.
At the start of each session, load the `caveman` skill via the skill tool and
apply it at `full` intensity to all prose output.
If I ask for another intensity (`lite`, `ultra`, `wenyan-*`), use that instead.
If I say "normal mode" / "plain English", drop caveman for the rest of the session.
Caveman applies to prose only — never to code, commands, file contents, commit
messages (use the caveman-commit rules), or anything meant to be copy-pasted.
