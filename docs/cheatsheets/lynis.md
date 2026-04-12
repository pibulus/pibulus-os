# LYNIS — Security Auditing Tool

Audits your own system. Checks for hardening gaps, misconfigurations, exposed services,
weak permissions, and more. Run it on this Pi and you'll find things. That's the point.

---

## Run it

```bash
# Full system audit (takes ~2 minutes)
sudo lynis audit system

# Quick view of findings only
sudo lynis audit system --quick

# Save report to file
sudo lynis audit system --report-file /tmp/lynis-report.dat
```

---

## Reading the output

Lynis uses a traffic light system:

```
[OK]      — good, no action needed
[WARNING] — look at this
[SUGGESTION] — consider improving this
[FOUND]   — something was found, check context
```

At the end you get a **Hardening Index** score out of 100.
First run on a fresh Pi is usually 55-65. That's normal. The goal is to understand
each warning, not to blindly chase a high score.

---

## Common findings on a Pi and what they mean

```
Suggestion: Consider hardening SSH configuration
→ Edit /etc/ssh/sshd_config
→ Set: PermitRootLogin no
→ Set: PasswordAuthentication no (once you have SSH keys set up)

Warning: Found one or more vulnerable packages
→ sudo apt update && sudo apt upgrade

Suggestion: Install a file integrity tool
→ apt install aide  (then: aide --init)

Warning: No firewall active
→ sudo ufw enable
→ sudo ufw allow 22/tcp
```

---

## After fixing things

```bash
# Run again to see improvement
sudo lynis audit system

# Compare reports
sudo lynis audit system --report-file /tmp/new-report.dat
diff /tmp/old-report.dat /tmp/new-report.dat
```

---

## Philosophy

Lynis is a mirror. It shows you your own system as an attacker would start to see it.
The findings aren't failures — they're a to-do list. Work through them one at a time.

---

## Install

```bash
sudo apt install lynis
```
