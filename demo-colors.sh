#!/bin/bash

# Galadhrim v3.0 - Color Demo Script
# Run this in your terminal to see the colorful output!

# Define colors
RED="\033[1;31m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
WHITE="\033[1;37m"
LIGHT_MAG="\033[1;95m"
LIGHT_YEL="\033[1;93m"
BRIGHT_CYAN="\033[1;96m"
RESET="\033[0m"

clear

# Header
echo -e "${BRIGHT_CYAN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "     🚀 Galadhrim v3.0 - Agent Color Demo 🚀      "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}\n"

# Phase 1: Discovery
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}📍 PHASE 1: DISCOVERY${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "Detecting: TypeScript, JavaScript, Python, Java..."
echo "Found: 127 files, 45,823 LOC"
echo ""
sleep 1

# Phase 2: Pattern Scan
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${YELLOW}🔍 PHASE 2: PATTERN SCANNING${RESET}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "Scanning for security patterns... ✓"
echo "Scanning for performance hotspots... ✓"
echo "Identified 27 hotspot files for deep analysis"
echo ""
sleep 1

# Phase 3: Multi-Agent Analysis
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}⚡ PHASE 3: MULTI-AGENT ANALYSIS${RESET}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Tier 1
echo -e "${MAGENTA}▶ TIER 1 - Critical Agents (Parallel)${RESET}"
echo -e "${RED}  🚀 security-agent${RESET} - Analyzing security vulnerabilities..."
echo -e "${YELLOW}  🚀 performance-agent${RESET} - Detecting performance bottlenecks..."
sleep 0.5
echo -e "${RED}     ✓ Found: SQL injection in UserController.java:45${RESET}"
echo -e "${YELLOW}     ✓ Found: N+1 query in ProductService.ts:89${RESET}"
sleep 0.5
echo -e "${RED}  ✅ security-agent completed - 8 findings${RESET}"
echo -e "${YELLOW}  ✅ performance-agent completed - 15 findings${RESET}"
echo ""

# Tier 2
echo -e "${MAGENTA}▶ TIER 2 - Data & Concurrency (Parallel)${RESET}"
echo -e "${MAGENTA}  🚀 concurrency-agent${RESET} - Checking thread safety..."
echo -e "${CYAN}  🚀 data-integrity-agent${RESET} - Validating transactions..."
sleep 0.5
echo -e "${MAGENTA}     ✓ Found: Race condition in OrderProcessor.py:234${RESET}"
echo -e "${CYAN}     ✓ Found: Missing transaction in PaymentService.java:67${RESET}"
sleep 0.5
echo -e "${MAGENTA}  ✅ concurrency-agent completed - 4 findings${RESET}"
echo -e "${CYAN}  ✅ data-integrity-agent completed - 9 findings${RESET}"
echo ""

# Tier 3
echo -e "${MAGENTA}▶ TIER 3 - Architecture & Resilience (Parallel)${RESET}"
echo -e "${BLUE}  🚀 architecture-agent${RESET} - Analyzing structure..."
echo -e "${GREEN}  🚀 resilience-agent${RESET} - Checking fault tolerance..."
sleep 0.5
echo -e "${BLUE}     ✓ Found: God class >500 LOC in MainController.ts${RESET}"
echo -e "${GREEN}     ✓ Found: Missing timeout in ExternalAPI.js:123${RESET}"
sleep 0.5
echo -e "${BLUE}  ✅ architecture-agent completed - 7 findings${RESET}"
echo -e "${GREEN}  ✅ resilience-agent completed - 11 findings${RESET}"
echo ""

# Tier 4
echo -e "${MAGENTA}▶ TIER 4 - Quality & Observability (Parallel)${RESET}"
echo -e "${WHITE}  🚀 observability-agent${RESET} - Reviewing logging..."
echo -e "${LIGHT_MAG}  🚀 api-design-agent${RESET} - Checking REST standards..."
echo -e "${LIGHT_YEL}  🚀 code-quality-agent${RESET} - Measuring complexity..."
sleep 0.5
echo -e "${WHITE}  ✅ observability-agent completed - 18 findings${RESET}"
echo -e "${LIGHT_MAG}  ✅ api-design-agent completed - 13 findings${RESET}"
echo -e "${LIGHT_YEL}  ✅ code-quality-agent completed - 22 findings${RESET}"
echo ""

# Phase 4: Assembly
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}📊 PHASE 4: ASSEMBLY & DEDUPLICATION${RESET}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "Merging findings from 9 agents..."
echo "Deduplicating... removed 12 duplicates"
echo "Sorting by severity and category..."
echo ""
sleep 1

# Results Summary with Severity Colors
echo -e "${BRIGHT_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BRIGHT_CYAN}✨ ANALYSIS COMPLETE${RESET}"
echo -e "${BRIGHT_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "📊 Findings by Severity:"
echo -e "  ${RED}🔴 CRITICAL: 4 issues${RESET} (immediate action required)"
echo -e "  ${YELLOW}🟠 HIGH: 12 issues${RESET} (fix before release)"
echo -e "  ${BLUE}🟡 MEDIUM: 35 issues${RESET} (address in next sprint)"
echo -e "  ${GREEN}🟢 LOW: 47 issues${RESET} (improvement suggestions)"
echo ""
echo "💾 Report saved to: reports/code-review-$(date +%Y%m%d-%H%M%S).md"
echo ""

# Agent Color Legend
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${WHITE}🎨 AGENT COLOR LEGEND${RESET}"
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${RED}● security-agent${RESET}        ${YELLOW}● performance-agent${RESET}"
echo -e "  ${MAGENTA}● concurrency-agent${RESET}     ${CYAN}● data-integrity-agent${RESET}"
echo -e "  ${BLUE}● architecture-agent${RESET}    ${GREEN}● resilience-agent${RESET}"
echo -e "  ${WHITE}● observability-agent${RESET}   ${LIGHT_MAG}● api-design-agent${RESET}"
echo -e "  ${LIGHT_YEL}● code-quality-agent${RESET}"
echo ""

echo -e "${BRIGHT_CYAN}🚀 Total execution time: 3 minutes 27 seconds${RESET}"
echo ""