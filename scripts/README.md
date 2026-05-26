# Scripts

对外公开命令只保留三条：

```bash
jcs i
jcs inject /path/to/project --force
jcs u --force
```

等价脚本：

```bash
bash scripts/quick-install.sh
bash scripts/inject-current-project.sh /path/to/project --force
bash scripts/uninstall-skills.sh --force
```

scripts 目录中其他脚本属于内部维护，不作为对外主入口。
