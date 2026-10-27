# AWS Mini-SOC: Path Traversal Detection with Wazuh Cloud

## Overview

This project demonstrates a small cloud-hosted security monitoring lab built with Terraform, an Ubuntu EC2 instance, a deliberately vulnerable Python web application, and Wazuh Cloud.

The objective was to simulate a path traversal attack against a test application, collect application logs centrally, create a custom Wazuh detection rule, and verify that the event generated a security alert.

**Project type:** Cloud security monitoring and detection engineering  
**Infrastructure as Code:** Terraform  
**Endpoint:** Ubuntu Server on AWS EC2  
**SIEM / Security Monitoring:** Wazuh Cloud  
**Log format:** JSON

## Objectives

- Provision cloud infrastructure using Terraform.
- Restrict access to the test application using an AWS security group.
- Deploy a deliberately vulnerable web application for controlled testing.
- Generate structured application logs containing request details and response status.
- Forward application logs to Wazuh Cloud.
- Create and validate custom detection rules.
- Investigate the resulting alert and document the findings.

## Architecture

```text
Security Analyst Laptop
        |
        | HTTP test request
        v
AWS EC2 — Ubuntu
  ├── Python test web application
  ├── JSON access log
  ├── Linux audit logging
  └── Wazuh Agent
        |
        | Log forwarding
        v
Wazuh Cloud
  ├── JSON decoder
  ├── Custom detection rules
  └── Security alert
```

AWS infrastructure is provisioned with Terraform. The application runs on a dedicated, unprivileged Linux service account, and inbound access is restricted by the security group.

## Attack Simulation

A controlled HTTP request was sent to the test application's file-reading endpoint using a path traversal sequence:

```bash
curl -sS --get \
  --data-urlencode 'file=../synthetic-secret.txt' \
  http://<EC2-PUBLIC-IP>:8080/read
```

The application returned HTTP `200` and the contents of a synthetic test file. The file contained dummy values, not real credentials.

## Logging and Detection

The application writes JSON records to:

`/var/log/soc-lab-web/access.json`

Relevant fields include:

- `timestamp`
- `source_ip`
- `request`
- `status`
- `event`
- `user_agent`

The Wazuh agent collects this file, and Wazuh Cloud decodes the records as JSON.

Custom rule `100500` was used to validate basic event matching. Custom rule `100501` was then used to match the observed path traversal request pattern.

The test successfully generated a Wazuh Cloud alert for rule `100501`.

## Results

- [x] AWS infrastructure provisioned using Terraform.
- [x] Test application deployed on Ubuntu EC2.
- [x] Path traversal behavior reproduced with a synthetic file.
- [x] Application JSON logging verified.
- [x] Wazuh Cloud log collection and JSON decoding confirmed.
- [x] Custom detection alert observed in Wazuh Cloud.

## Security Considerations

This application is intentionally vulnerable and is intended only for a controlled lab. It must not be exposed to unrestricted public access.

The current detection matches a known test request pattern. It is not a comprehensive path traversal detection system and does not, by itself, establish malicious intent. The HTTP response status and application log support the investigation, but conclusions should be based on the full evidence.

No real credentials or sensitive files should be used in this lab.

## Repository Structure

```text
soc-lab-aws/
├── main.tf
├── .gitignore
├── README.md
├── docs/
│   └── incident-report.md
 ── rules/
    └── soc_lab_traversal_rules.xml
```

## Future Improvements

- Add broader traversal detection with proper normalization and decoding.
- Correlate application logs with Linux audit events.
- Test benign requests to measure false positives.
- Add alert triage guidance and a repeatable validation procedure.
- Document deployment and cleanup procedures.

## Disclaimer

This project is for educational and defensive security purposes. The vulnerability was tested against infrastructure controlled by the author using synthetic data.
