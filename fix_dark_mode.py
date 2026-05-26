import os
import re

def main():
    dirs = ['lib/dashboards', 'lib/auth', 'lib/widgets']
    for d in dirs:
        if not os.path.exists(d):
            continue
        for root, dirs_list, files in os.walk(d):
            for file in files:
                if not file.endswith('.dart'):
                    continue
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()

                new_content = content
                
                # 1. Remove const from widgets that might contain Theme.of(context) dynamically
                new_content = re.sub(
                    r'const\s+(Scaffold|Container|BoxDecoration|Card|Icon|Text|Column|Row|Padding|SizedBox|Center|AppBar|CircleAvatar|ListTile|ElevatedButton|TextButton|TabBar|TabBarView|Tab|Wrap|Expanded)\b([^a-zA-Z])',
                    r'\1\2',
                    new_content
                )

                # 2. Scaffold Backgrounds
                new_content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFFF4F7FC\)', r'backgroundColor: Theme.of(context).scaffoldBackgroundColor', new_content)
                new_content = re.sub(r'backgroundColor:\s*Color\(0xFFF4F7FC\)', r'backgroundColor: Theme.of(context).scaffoldBackgroundColor', new_content)
                new_content = re.sub(r'color:\s*const\s*Color\(0xFFF4F7FC\)', r'color: Theme.of(context).scaffoldBackgroundColor', new_content)
                new_content = re.sub(r'color:\s*Color\(0xFFF4F7FC\)', r'color: Theme.of(context).scaffoldBackgroundColor', new_content)

                # 3. AppBar & Cards White backgrounds
                new_content = re.sub(r'backgroundColor:\s*Colors\.white', r'backgroundColor: Theme.of(context).cardColor', new_content)

                # 4. Containers and BoxDecoration White backgrounds
                def replace_line_white(line):
                    if 'TextStyle' in line or 'Text(' in line or 'Icon(' in line or 'IconThemeData' in line:
                        return line
                    return re.sub(r'color:\s*Colors\.white', r'color: Theme.of(context).cardColor', line)
                
                lines = new_content.split('\n')
                for i in range(len(lines)):
                    lines[i] = replace_line_white(lines[i])
                new_content = '\n'.join(lines)

                # 5. Text Colors (Blacks and Greys)
                new_content = re.sub(r'color:\s*Colors\.black87', r'color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87', new_content)
                new_content = re.sub(r'color:\s*Colors\.black54', r'color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54', new_content)
                new_content = re.sub(r'color:\s*Colors\.black(?![0-9])', r'color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black', new_content)
                new_content = re.sub(r'color:\s*Colors\.grey\.shade600', r'color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade600', new_content)

                # 6. Brand Primary text color -> white in dark mode
                def replace_primary_dark(line):
                    if 'TextStyle' in line or 'Icon(' in line or 'color: const Color(0xFF05398F)' in line and 'AppBar' in new_content:
                        # Be somewhat safe
                        return re.sub(r'color:\s*const\s*Color\(0xFF05398F\)|color:\s*Color\(0xFF05398F\)', r'color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF05398F)', line)
                    return line
                
                lines = new_content.split('\n')
                for i in range(len(lines)):
                    lines[i] = replace_primary_dark(lines[i])
                new_content = '\n'.join(lines)

                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)

if __name__ == '__main__':
    main()
