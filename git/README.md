Set up two Git identities (personal and corporate) by using conditional includes in `~/.gitconfig`, so Git picks the right name/email based on the folder where the repo lives.[1][2][3]

## 1. Create two config snippets

In your home directory, create:

`~/.gitconfig-personal`:

```ini
[user]
    name = Your Personal Name
    email = your.personal+git@example.com
```

`~/.gitconfig-corporate`:

```ini
[user]
    name = Your Corporate Name
    email = your.corporate@company.com
```

These define the two profiles.[4][5]

## 2. Organize your repos in two base folders

For example:

```text
~/code/personal/   # all personal repos here
~/code/corporate/  # all work/corporate repos here
```

This lets Git use directory-based conditional config.[6][1]

## 3. Add conditional includes to `~/.gitconfig`

Edit `~/.gitconfig` to include the right profile based on the repo path:

```ini
[user]
    name = Default Name
    email = default@example.com

[includeIf "gitdir:~/code/personal/"]
    path = .gitconfig-personal

[includeIf "gitdir:~/code/corporate/"]
    path = .gitconfig-corporate
```

- Any repo under `~/code/personal/` uses the personal identity.  
- Any repo under `~/code/corporate/` uses the corporate identity.[5][7][8]

## 4. Verify per repo

Inside a personal repo:

```bash
cd ~/code/personal/learn-tf
git config user.name
git config user.email
```

Inside a corporate repo:

```bash
cd ~/code/corporate/some-work-repo
git config user.name
git config user.email
```
