---
v: 3

title: CoRIM profile for AMD SEV-SNP attestation report
abbrev: CoRIM-SEV
docname: draft-deeglaze-amd-sev-snp-corim-profile-latest
category: std
consensus: true
submissiontype: IETF

ipr: trust200902
area: "Security"
workgroup: "Remote ATtestation ProcedureS"
keyword: RIM, RATS, attestation, verifier, supply chain

stand_alone: true
pi:
  toc: yes
  sortrefs: yes
  symrefs: yes
  tocdepth: 6

author:
- ins: D. Glaze
  name: Dionna Glaze
  org: Google LLC
  email: dionnaglaze@google.com

contributor:
- ins: Y. Deshpande
  name: Yogesh Deshpande
  organization: arm
  email: yogesh.deshpande@arm.com
  contribution: >
      Yogesh Deshpande contributed to the data model by providing advice about CoRIM founding principles.

normative:
  RFC3280:
  RFC4122:
  RFC5480:
  RFC5758:
  RFC8174:
  RFC8610: cddl
  RFC9334: rats-arch
  RFC9090: cbor-oids
  X.690:
    title: >
      Information technology — ASN.1 encoding rules:
      Specification of Basic Encoding Rules (BER), Canonical Encoding
      Rules (CER) and Distinguished Encoding Rules (DER)
    author:
      org: International Telecommunications Union
    date: 2015-08
    seriesinfo:
      ITU-T: Recommendation X.690
    target: https://www.itu.int/rec/T-REC-X.690
  IANA.named-information: named-info

informative:
  I-D.ietf-rats-corim: rats-corim
  SEV-SNP.API:
    title: SEV Secure Nested Paging Firmware ABI Specification
    author:
      org: Advanced Micro Devices Inc.
    seriesinfo: Revision 1.55
    date: September 2023
    target: https://www.amd.com/content/dam/amd/en/documents/epyc-technical-docs/specifications/56860.pdf
  GHCB:
    title: SEV-ES Guest-Hypervisor Communication Block Standardization
    author:
      org: Advanced Micro Devices Inc.
    seriesinfo: Revision 2.03
    date: July 2023
    target: https://www.amd.com/content/dam/amd/en/documents/epyc-technical-docs/specifications/56421.pdf
  VCEK:
    title: Versioned Chip Endorsement Key (VCEK) Certificate and KDS Interface Specification
    author:
      org: Advanced Micro Devices Inc.
    seriesinfo: Revision 0.51
    date: January 2023
    target: https://www.amd.com/content/dam/amd/en/documents/epyc-technical-docs/specifications/57230.pdf
  VLEK:
    title: Versioned Loaded Endorsement Key (VLEK) Certificate Definition
    author:
      org: Advanced Micro Devices Inc.
    seriesinfo: Revision 0.10
    date: October 2023
    target: https://www.amd.com/content/dam/amd/en/documents/epyc-technical-docs/user-guides/58369-010-versioned-loaded-endorsement-key-certificate-definition.pdf
  SEC1:
    title: >
      Standards for Efficient Cryptography Group (SECG), "SEC1: Elliptic Curve Cryptography"
    author:
      org: Certicom Corp.
    seriesinfo: Version 1.0
    date: September 2000
    target: https://www.secg.org/SEC1-Ver-1.0.pdf
  AMD.SPM:
    title: >
      AMD64 Architecture Programmer’s Manual, Volume 2: System Programming
    author:
      org: Advanced Micro Devices Inc.
    seriesinfo: Revision 3.42
    date: March 2024
    target: https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/24593.pdf

entity:
  SELF: "RFCthis"

--- abstract

AMD Secure Encrypted Virtualization with Secure Nested Pages (SEV-SNP) attestation reports comprise of reference values and cryptographic key material that a Verifier needs in order to appraise Attestation Evidence produced by an AMD SEV-SNP virtual machine.
This document specifies the information elements for representing SEV-SNP Reference Values in CoRIM format.

--- middle

# Introduction {#sec-intro}

TODO: write after content.

#  Conventions and Definitions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [RFC2119] [RFC8174] when, and only when, they appear in all capitals, as shown here.

The reader is assumed to be familiar with the terms defined in {{-rats-corim}} and Section 4 of {{-rats-arch}}.
The syntax of data descriptions is CDDL as specified in {{-cddl}}.

# AMD SEV-SNP Attestation Reports

The AMD SEV-SNP attestation scheme in [SEV-SNP.API] contains measurements of security-relevant configuration of the host environment and the launch configuration of a SEV-SNP VM.
This draft documents the normative representation of attestation report Evidence as a CoRIM profile.

AMD-SP:
  AMD Secure Processor.
  A separate core that provides the confidentiality and integrity properties of AMD SEV-SNP.
  The function that is relevant to this document is its construction of signed virtual machine attestation reports.

VCEK:
  Versioned Chip Endorsement Key.
  A key for signing the SEV-SNP Attestation Report.
  The key is derived from a unique device secret as well as the security patch levels of relevant host components.

VLEK:
  Version Loaded Endorsement Key.
  An alternative SEV-SNP Attestation Report signing key that is derived from a secret shared between AMD and a Cloud Service Provider.
  The key is encrypted with a per-device per-version wrapping key that is then decrypted and stored by the AMD-SP.

VEK:
  Either a VCEK or VLEK.

## AMD SEV-SNP CoRIM Profile

AMD SEV-SNP launch endorsements are carried in one or more CoMIDs inside a CoRIM.

The profile attribute in the CoRIM MUST be present and MUST have a single entry set to the uri http://amd.com/please-permalink-me as shown in {{figure-profile}}.


~~~ cbor-diag
/ corim-map / {
  / corim.profile / 3: [
    32("http://amd.com/please-permalink-me")
  ]
  / ... /
}
~~~
{: #figure-profile title="SEV-SNP attestation profile version 1, CoRIM profile" }

### AMD SEV-SNP Target Environment

The `ATTESTATION_REPORT` structure as understood in the RATS Architecture [RFC9334] is a signed collection of Claims that constitute Evidence about the Target Environment.
The Attester for the `ATTESTATION_REPORT` is specialized hardware that will only run AMD-signed firmware.

The `class-id` for the Target Environment measured by the AMD-SP is the tagged OID `#6.111(1.3.6.1.4.1.3704.2.1)`.
The launched VM on SEV-SNP has an ephemeral identifier `REPORT_ID`.
If the VM is the continuation of some instance as carried by a migration agent, there is also a possible `REPORT_ID_MA` value to identify the instance.
The attester, however, is always on the same `CHIP_ID`.
Given that the `CHIP_ID` is not uniquely identifying for a VM instance, it is better classified as a group.
The `CSP_ID` is similarly better classified as a group.
Either the `CHIP_ID` or the `CSP_ID` may be represented in the `group` codepoint as a tagged-bytes.
If the `SIGNING_KEY` bit of the attestation report is 1, then the `group` MUST be the `CSP_ID` of the VLEK.

~~~ cbor-diag
/ environment-map / {
  / class-map / {
    / class-id: / 0 => #6.111(1.3.6.1.4.1.3704.2.1)
  }
  / instance: / 1 => #6.563({
    / report-id: / 0 => REPORT_ID,
    / report-id-ma: / 1 => REPORT_ID_MA
    })
  / group: / 2 => #6.560(CHIP_ID)
}
~~~

### AMD SEV-SNP Attestation Report measurement values extensions

The fields of an attestation report that have no direct analog in the base CoRIM CDDL are given negative codepoints to be specific to this profile.

The `GUEST_POLICY` field's least significant 16 bits represent a Major.Minor minimum version number:

~~~ cddl
{::include cddl/sevsnpvm-policy-record.cddl}
~~~

The policy's minimum ABI version is assigned codepoint -1:

~~~ cddl
{::include cddl/sevsnpvm-policy-abi-ext.cddl}
~~~

The attestation report's `FAMILY_ID` and `IMAGE_ID` are indirectly represented through an extension to `$version-scheme` as described in {{sec-version-scheme}}.

The attestation report's `VMPL` field is assigned codepoint -2:

~~~ cddl
{::include cddl/sevsnpvm-vmpl-ext.cddl}
~~~

The attestation report's `HOST_DATA` is assigned codepoint -3:

~~~ cddl
{::include cddl/sevsnpvm-hostdata-ext.cddl}
~~~

The SEV-SNP firmware build number and Minor.Minor version numbers are provided for both the installed and committed versions of the firmware to account for firmware hotloading.
The three values are captured in a record type `sevsnphost-sp-fw-version-record`:

~~~ cddl
{::include cddl/sevsnphost-sp-fw-version-record.cddl}
~~~

The current build/major/minor of the SP firmware is assigned codepoint -4:

~~~ cddl
{::include cddl/sevsnphost-spfw-current-ext.cddl}
~~~

The committed build/major/minor of the SP firmware is assigned codepoint -5:

~~~ cddl
{::include cddl/sevsnphost-spfw-committed-ext.cddl}
~~~

The host components other than AMD SP firmware are relevant to VM security posture, so a combination of host components' security patch levels are included as TCB versions.
The TCB versions are expressed as a 64-bit number where each byte corresponds to a different component's security patch level.
Reference value providers MUST provide an overall minimum value for the combination of components, since lexicographic ordering is vulnerable to downgrade attacks.
Tools for human readability MAY present the TCB version a component-wise manner, but that is outside the scope of this document.

The `CURRENT_TCB` version of the host is assigned codepoint -6:

~~~ cddl
{::include cddl/sevsnphost-current-tcb-ext.cddl}
~~~

The `COMMITTED_TCB` version of the host is assigned codepoint -7:

~~~ cddl
{::include cddl/sevsnphost-committed-tcb-ext.cddl}
~~~

The `LAUNCH_TCB` version of the host is assigned codepoint -8:

~~~ cddl
{::include cddl/sevsnphost-launch-tcb-ext.cddl}
~~~

The `REPORTED_TCB` version of the host is assigned codepoint -9:

~~~ cddl
{::include cddl/sevsnphost-reported-tcb-ext.cddl}
~~~

The `GUEST_POLICY` boolean flags are added as extensions to `$$flags-map-extension`, starting from coedpoint -1.

~~~ cddl
{::include cddl/sevsnpvm-guest-policy-flags-ext.cddl}
~~~

There are 47 available bits for selection when the mandatory 1 in position 17 and the ABI Major.Minor values are excluded from the 64-bit `GUEST_POLICY`.
The `PLATFORM_INFO` bits are host configuration that are added as extensions to `$$flags-map-extension` starting at `-49`.

~~~ cddl
{::include cddl/sevsnphost-platform-info-flags-ext.cddl}
~~~

#### Version scheme extension {#sec-version-scheme}

Extend the `$version-scheme` type with as follows

~~~ cddl
{::include cddl/sevsnpvm-version-scheme-ext.cddl}
~~~

The `-1` scheme is a string representation of the two 128-bit identifiers in hexadecimal encoding as separated by `/`.
The scheme allows for fuzzy comparison with `_` as a wildcard on either side of the `/`.

An endorsement provider MAY use a different version scheme for the `&(version: 0)` codepoint.

#### Notional Instance Identity {#sec-id-tag}

A CoRIM instance identifier is universally unique, but there are different notions of identity within a single attestation report that are each unique within their notion.
A notional instance identifier is a tagged CBOR map from integer codepoint to opaque bytes.

~~~ cddl
{::include cddl/int-bytes-map.cddl}
~~~

Profiles may restrict which integers are valid codepoints, and may restrict the respective byte string sizes.
For this profile, only codepoints 0 and 1 are valid.
The expected byte string sizes are 32 bytes.
For the `int-bytes-map` to be an interpretable extension of `$instance-id-type-choice`, there is `tagged-int-bytes-map`:

~~~ cddl
{::include cddl/tagged-int-bytes-map.cddl}
~~~

### AMD SEV-SNP Evidence Translation

The `ATTESTATION_REPORT` Evidence is converted into a CoRIM `endorsed-triple-record` using the rules in this section.
Fields of `ATTESTATION_REPORT` are referred to by their assigned names in [SEV-SNP.API].
If the `ATTESTATION_REPORT` contains `ID_BLOCK` information, the relevant fields will be represented in a second `endorsed-triple-record` with a different `authorized-by` field value, as per the merging rules of {{-rats-corim}}.

#### `environment-map`

*  The `environment-map / class / class-id` field SHALL be set to the BER {{X.690}} encoding of OID {{-cbor-oids}} `1.3.6.1.4.1.3704.2.1` and tagged with #6.111.
*  The `environment-map / instance ` field SHALL be set to an `int-bytes-map` tagged with #6.111 with at least one codepoint 0 or 1.
   If codepoint 0 is populated, it SHALL be set to `REPORT_ID`.
   If codepoint 1 is populated, it SHALL be set to `REPORT_ID_MA`.
*  The `environment-map / group ` field SHALL be set to the VLEK `csp_id` and tagged with #6.111 if `SIGNING_KEY` is 1.
   If `SIGNING_KEY` is 0, the field MAY be set to the VCEK `hwid` and tagged with #6.111.

#### `measurement-map`

The `mkey` is left unset.
The `authorized-by` key SHALL be set to a representation of the VEK that signed the `ATTESTATION_REPORT`, or a key along the certificate path to a self-signed root, i.e., the ASK, ASVK, or ARK for the product line.
The `measurement-values-map` is set as described in the following section.

#### `measurement-values-map`

The function `is-set(x, b)` represents whether the bit at position `b` is set in the number `x`.

*  The `digests: 2` codepoint SHALL be set to either `[ / digest / { alg: 7 val: MEASUREMENT } ]` or `[ / digest / { alg: "sha-384" val: MEASUREMENT } ]` as assigned in {{-named-info}}.

*  The `&(flags: 3) / flags-map / sevsnpvm-policy-smt-allowed` codepoint SHALL be set to `is-set(GUEST_POLICY, 16`.
*  The `&(flags: 3) / flags-map / sevsnpvm-policy-migration-agent-allowed` codepoint SHALL be set to `is-set(GUEST_POLICY, 18)`.
*  The `&(flags: 3) / flags-map / sevsnpvm-policy-debug-allowed` codepoint SHALL be set to `is-set(GUEST_POLICY, 19)`.
*  The `&(flags: 3) / flags-map / sevsnpvm-policy-single-socket-only` codepoint SHALL be set to `is-set(GUEST_POLICY, 20)`.
*  The `&(flags: 3) / flags-map / sevsnpvm-policy-cxl-allowed` codepoint SHALL be set to `is-set(GUEST_POLICY, 21)`.
*  The `&(flags: 3) / flags-map / sevsnpvm-policy-mem-aes-256-xts-required` codepoint SHALL be set to `is-set(GUEST_POLICY, 22)`.
*  The `&(flags: 3) / flags-map / sevsnpvm-policy-rapl-must-be-disabled` codepoint SHALL be set to `is-set(GUEST_POLICY, 23)`.
*  The `&(flags: 3) / flags-map / sevsnpvm-policy-ciphertext-hiding-must-be-enabled` codepoint SHALL be set to `is-set(GUEST_POLICY, 24)`.
*  The `&(flags: 3) / flags-map / sevsnphost-smt-enabled` codepoint SHALL be set to `is-set(PLATFORM_INFO, 0)`.
*  The `&(flags: 3) / flags-map / sevsnphost-tsmu-enabled` codepoint SHALL be set to `is-set(PLATFORM_INFO, 1)`.
*  The `&(flags: 3) / flags-map / sevsnphost-ecc-mem-reported-enabled` codepoint SHALL be set to `is-set(PLATFORM_INFO, 2)`.
*  The `&(flags: 3) / flags-map / sevsnphost-rapl-disabled` codepoint SHALL be set to `is-set(PLATFORM_INFO, 3)`.
*  The `&(flags: 3) / flags-map / sevsnphost-ciphertext-hiding-enabled` codepoint SHALL be set to `is-set(PLATFORM_INFO, 4)`.
*  The `&(sevsnpvm-policy-abi: -1)` codepoint SHALL be set to  `[ ABI_MAJOR, ABI_MINOR ]`.
*  The `&(sevsnpvm-vmpl: -2)` codepoint SHALL be set to `VMPL`.
*  The `&(sevsnpvm-hostdata: -3)` codepoint SHALL be set to `HOSTDATA` if nonzero. It MAY be set to `HOSTDATA` if all zeroes.
*  The `&(sevsnphost-sp-fw-current: -4)` codepoint SHALL be set to `[ CURRENT_BUILD, CURRENT_MAJOR, CURRENT_MINOR ]`.
*  The `&(sevsnphost-sp-fw-committed: -5)` codepoint SHALL be set to `[ COMMITTED_BUILD, COMMITTED_MAJOR, COMMITTED_MINOR ]`.
*  The `&(sevsnphost-current-tcb: -6)` codepoint SHALL be set to `552(CURRENT_TCB)`.
*  The `&(sevsnphost-committed-tcb: -7)` codepoint SHALL be set to `552(COMMITTED_TCB)`
*  The `&(sevsnphost-launch-tcb: -8)` codepoint SHALL be set to `552(LAUNCH_TCB)`.
*  The `&(sevsnphost-reported-tcb: -9)` codepoint SHALL be set to `552(REPORTED_TCB)`.

If `ID_BLOCK` information is available, it appears in its own `endorement-triple-record` with additional values in `authorized-by` beyond the attestation key.
The `authorized-by` field is extended with `32780(ID_KEY_DIGEST)`, and if `AUTHOR_KEY_EN` is 1, then it is also extended with `32780(AUTHOR_KEY_DIGEST)`.
The Verifier MAY use a base CDDL CoRIM `$crypto-key-type-choice` representation if its public key information's digest is equal to the #6.32780-tagged bytes, as described it {{sec-key-digest}}.

*  The `version: 0` codepoint SHALL be set to
~~~cbor-diag
/ version-map / {
  / version: / 0 => hexlify(FAMILY_ID) '/' hexlify(IMAGE_ID)
  / version-scheme: -1 / => &(sevsnpvm-familyimageid-hex: -1)
}
~~~
where `hexlify` is a function that translates the a byte string to its hexadecimal string encoding.

*  The `&(svn: 1)` codepoint SHALL be set to `552(GUEST_SVN)`.
*  The `&(digests: 2)` codepoint is in the triple record.
*  The `&(flags: 3) / flags-map` codepoints prefixed by `sevsnpvm-policy` SHALL be set in the triple's `&(flags: 3)` entry as per above translation rules.

##### TCB comparison

The Verifier SHALL use tho `svn-type-choice` comparison algorithm from {-rats-corim}}.

#### Key digest comparison {#sec-key-digest}

When `ID_BLOCK` is used, the full key information needed for signature verification is provided by the VMM at launch in an `ID_AUTH` structure.
The SNP firmware verifies the signatures and adds digests of the signing key(s) to the attestation report as evidence of successful signature verification.
When a Verifier does not have access to the original public key information used in `ID_AUTH`, the attestation report key digests can still be used as a representation of authority.

The APPENDIX: Digital Signatures section of [SEV-SNP.API] specifies a representation of public keys and signatures.
An attestation report key digest will be a SHA-384 digest of the 0x403 byte buffer representation of a public key.
If an author key is used, its signature of the ID_KEY is assumed to exist and have passed given the SNP firmware specification.

If a `$crypto-key-type-choice` key representation specifies an algorithm and parameters that are included in the Digital Signatures appendix, it is comparable to a #6.32780-tagged byte string.

*  Two #6.32780-tagged byte strings match if and only if their encodings are bitwise equal.
*  A thumbprint representation of a key is not comparable to a #6.32780-tagged byte string since the parameters are not extractable.
*  A PKIX public key (#6.554-tagged `tstr`) or PKIX certificate (#6.555-tagged `tstr`) MAY be comparable to a #6.32780-tagged byte string.

The [RFC3280] specified `AlgorithmIdentifier` has optional parameters based on the algorithm identifier.
The AMD signature algorithm `1h` corresponds to algorithm `ecdsa-with-sha384` from section 3.2 of [RFC5758], but the parameters MUST be omitted.
The `SubjectPublicKeyInfo` is therefore `id-ecPublicKey` from section 2.1.1 of [RFC5480] to further allow the curve to be specified, despite not further specifying that the signature is of a SHA-384 digest.
The AMD ECSDA curve name `2h` corresponds to named curve `secp384r1` from section 2.2 of [RFC5480].
The `ECPoint` conversion routines in section 2 of [SEC1] provide guidance on how the `QX` and `QY` little-endian big integers zero-padded to 72 bytes may be constructed.

## AMD SEV-SNP Launch Event Log

The composition of a SEV-SNP VM may be comprised of measurements from multiple principals, such that no one principal has absolute authority to endorse the overall measurement value represented in the attestation report.
If one principal does have that authority, the `ID_BLOCK` mechanism provides a convenient launch configuration endorsement mechanism without need for distributing a CoRIM.
This section documents an event log format the Virtual Machine Monitor (VMM) may construct at launch time and provide in the data pages of an extended guest request, as documented in [GHCB].

The content media type shall be `application/vnd.amd.sevsnp.launch-updates+cbor` for the encoding of a `sevsnp-launch-configuration-map`:

~~~ cddl
{::include cddl/sevsnp-launch-configuration-map.cddl}
~~~

*  The `fms` field if included SHALL contain the CPUID[1]_EAX value masked with `0x0fff3fff` to provide chip family, model, stepping information.
  If not included, the Verifier may reference the VEK certificate's extension for `productName`.
*  The `sevsnpvm-launch-baseline` field if not included is SHALL be interpreted as an all zero SHA-384 digest.
The calculation of the launch measurement SHALL use the value is the initial `PAGE_INFO`'s `DIGEST_CUR` value.
*  The `sevsnpvm-launch-updates` field contains an ordered list of inputs to the `SNP_LAUNCH_UPDATE` command:

~~~ cddl
{::include cddl/sevsnp-launch-update-sequence.cddl}
~~~

The `sevsnp-launch-update-data-map` contains all fields of the `PAGE_INFO` structure that are needed for reconstructing a measurement.
If an update repeats many times, such as an application processor VMSA, then that can be compressed with the `repeat` field.

The bits 1..3 encode the PAGE_TYPE as documented in the [SEV-SNP.API].
The content codepoint MUST NOT be present if the page type is neither `PAGE_TYPE_NORMAL` (01h) nor `PAGE_TYPE_VMSA` (02h).

For the VMM, there are some updates it does on behalf of a different principal than the firmware vendor, so it may choose to pass through some of the information about the launch measurement circumstances for separate appraisal.

The encoded `sevsnp-launch-configuration-map` may be found in the extended guest report data table for UUID `8dd67209-971c-4c7f-8be6-4efcb7e24027`.

The VMM is expected to provide all fields unless their default corresponds to the value used.

### VMSA evidence {#vmsa-evidence}

The VMM that assembles the initial VM state is also responsible for providing initial state for the vCPUs.
The vCPU secure save area is called the VMSA on SEV-ES.
The VMSA initial values can vary across VMMs, so it's the VMM provider's responsibility to sign their reference values.

The reset vector from the firmware also influences the VMSAs for application processors' `RIP` and `CS_BASE`, so the VMSA is not entirely determined by the VMM.
The digest alone for the VMSA launch update command is insufficient to represent the separately specifiable reference values when the GHCB AP boot protocol is not in use.

The bootstrap processor (BSP) and application processors (APs) typically have different initial values.
The APs typically all have the same initial value, so the `ap-vmsa` codepoint MAY be a single `sevsnp-vmsa-type-choice` to represent its replication.
Alternatively, each AP's initial VMSA may be individually specified with a list of `sevsnp-vmsa-type-choice`.

{::include cddl/sevsnp-repeated-vmsa.cddl}

All VMSA fields are optional.
A missing VMSA field in evidence is treated as its default value.
A missing VMSA field in a reference value is one less matching condition.

### VMSA default values

Unless otherwise stated, each field's default value is 0.
The [AMD.SPM] is the definitive source of initial state for CPU registers.
Figure {{figure-vmsa-defaults}} is a CBOR representation of the nonzero default values that correspond to initial CPU register values as of the cited revision's Table 14-1.


~~~ cbor-diag
/ sevsnp-vmsa-map-r1-55 / {
  / es: / 0 => / svm-vmcb-seg-map / { / attrib: / 1 => 0x92 / limit: / 2 => 0xffff }
  / cs: / 1 => / svm-vmcb-seg-map / {
    / selector: / 0 => 0xf000
    / attrib: / 1 => 0x9b
    / limit: / 2 => 0xffff
    / base: / 3 => 0xffff0000
  }
  / ss: / 2 => / svm-vmcb-seg-map / { / attrib: / 1 => 0x92 / limit: / 2 => 0xffff }
  / ds: / 3 => / svm-vmcb-seg-map / { / attrib: / 1 => 0x92 / limit: / 2 => 0xffff }
  / fs: / 4 => / svm-vmcb-seg-map / { / attrib: / 1 => 0x92 / limit: / 2 => 0xffff }
  / gs: / 5 => / svm-vmcb-seg-map / { / attrib: / 1 => 0x92 / limit: / 2 => 0xffff }
  / gdtr: / 6 => / svm-vmcb-seg-map / { / limit: / 2 => 0xffff }
  / ldtr: / 7 => / svm-vmcb-seg-map / { / attrib: / 1 => 0x82 / limit: / 2 => 0xffff }
  / idtr: / 8 => / svm-vmcb-seg-map / { / limit: / 2 => 0xffff }
  / tr: / 9 => / svm-vmcb-seg-map / { / attrib: / 1 => 0x83 / limit: / 2 => 0xffff }
  / cr0: / 33 => 0x10
  / dr7: / 34 => 0x400
  / dr6: / 35 => 0xffff0ff0
  / rflags: / 36 => 0x2
  / rip: / 37 => 0xfff0
  / g_pat: / 63 => 0x7040600070406
  / xcr0: / 97 => 0x1
}
~~~
{: #figure-vmsa-defaults title="SEV-SNP default VMSA values" }

The `rdx` is expected to be the FMS of the chip, but VMMs commonly disregard this, so it's left to a different configuration field.
A VMM provider may therefore sign reference values for a `sevsnp-launch-configuration-map` to specify non-default values for the BSP and AP state.

#### Example VMM reference values for VMSA

Qemu, AWS Elastic Compute Cloud (EC2), and Google Compute Engine (GCE), all use KVM, which initializes `cr4` and `efer` to non-default values.
The values for `cr4` and `efer` are different from the SPM to allow for `PSE` (page size extension) `SVME` (secure virtual machine enable).

Only Qemu follows the [AMD.SPM] specification for `rdx`, which is to match the family/model/stepping of the chip used.
GCE provides an `rdx` of `0x600` regardless, and EC2 provides `0` regardless.
GCE sets the `G_PAT` (guest page attribute table) register to `0x70406` to disable PA4-PA7.
Both Qemu and GCE set the `tr` attrib to `0x8b`, so it starts as a busy 32-bit TSS instead of the default 16-bit.
GCE sets `ds`, `es`, `fs`, `gs`, and `ss` attributes to `0x93`.

Qemu provides the RESET values on INIT for the `mxcsr`, `x87_ftw`, `x87_fcw` registers.

## AMD SEV-SNP Launch Event Log Appraisal

The `sevsnp-launch-configuration-map` is translated into a full sequence of `SNP_LAUNCH_UPDATE` commands on top of a baseline digest value to calculate following [SEV-SNP.API]'s documentation of digest calculation from `PAGE_INFO` structures.

The first `PAGE_INFO` structure uses the baseline digest as its `DIGEST_CUR`.
The following pseudocode for the function measurement computes the expected measurement of the endorsement format.
If this measurement equals the digests value with VCEK authority, then add the baseline and updates measurement values to the same ECT as the attestation report.

Since the VMM only has to provide the gpa, page type, and digest of the contents, the rest of the fields of a `sevsnp-launch-update-data-map` have default values when translated to a `PAGE_INFO` without the `DIGEST_CUR` field.
If the baseline is not provided, it is assumed to be all zeros.

~~~
measurement({fms, baseline, updates}) = iterate(baseline, appendmap(mk_page_info(fms), updates))

PAGE_SHIFT = 12
bitWidth(fms) = 48 if (fms >> 4) == 0xA00F0 ; Milan
bitWidth(fms) = 52 if (fms >> 4) == 0xA10F0 ; Genoa

top_gpfn(fms) = ((1 << bitWidth(fms)) - 1) >> PAGE_SHIFT
default_gpa(fms): uint64 = top_gpfn(fms) << PAGE_SHIFT

mk_page_info(fms)({page-type or PAGE_TYPE_NORMAL,
                   contents,
                   gpa or default_gpa(fms),
                   page-data or 0,
                   vmpl-perms or 0}):list[bytes] = [
  contents || {0x70, 0, page-type,
  page-data} || leuint64(vmpl-data) || leuint64(gpa),
]

appendmap(f, []) = []
appendmap(f, x:xs) = append(f(x), appendmap(f, xs))

iterate(digest_cur, []) = digest_cur
iterate(digest_cur, info:infos) = iterate(sha384(digest_cur || info), infos)
~~~

The `leuint64` metafunction translates a 64-bit unsigned integer into its little endian byte string representation.

### Comparisons for reference values

An "any" sequence number matches any sequence number.
The uint sequence number starts counting after the baseline matches.
If there is no reference baseline, the sequence numbers start at 0.
If there is a reference baseline, the VMM's provided baseline gets hash-combined with the provided updates until the digest equals the signed baseline, and the sequence numbers s
tart from the following update as if they are 1.
If there is no update that leads to a matching baseline value, no updates match.

The other `sevsnp-launch-update-data-map` codepoints must match all present codepoints with encoding equality.
The evidence ECT for the matching values are then split into a separate ECT to account for the added authority.

Note: the VMM may split its baseline and updates at any point, which will drop the specificity of individual updates.
The individual updates of a reference value MUST match individual updates from the VMM.
It is therefore advantageous to combine as many updates in the reference value into the baseline as is feasible.

### Example: OVMF with `SevMetadata`

The Open Virtual Machine Firmware project directs the VMM to not just load the UEFI at the top of the 4GiB memory range, but also measure referenced addresses with particular `SNP_LAUNCH_UPDATE` inputs.
Given that the firmware may be built by one party, the VMM another, and `SEV_KERNEL_HASHES` data yet another, the different data spread across the `SNP_LAUNCH_UPDATE` commands should be signed by the respective parties.

#### OVMF data

The GUID table at the end of the ROM is terminated by the GUID `96b582de-1fb2-45f7-baea-a366c55a082d` starting at offset `ROM_end - 0x30`.
At offset `ROM_end - 0x32` there is a length in a 16-bit little endian unsigned integer.
At offset `ROM_end - 0x32 - length` there is a table with format

| Type | Name |
| ---- | ---- |
| * | * |
| UINT8[Length] | Data |
| LE_UINT16 | Length |
| EFI_GUID | Name |
{: title="OVMF footer GUID table type description"}

`LE_UINT16` is the type of a little endian 16-bit unsigned integer.
`EFI_GUID` is the UUID format specified in section 4 of [RFC4122].
The footer GUID and length specifies the length of the table of entries itself, which does not include the footer.

Within this table there is an entry that specifies the guest physical address that contains the `SevMetadata`.

| Type | Name |
| ---- | ---- |
| LE_UINT32 | Address |
| LE_UINT16 | Length |
| EFI_GUID | dc886566-984a-4798-A75e-5585a7bf67cc |
{: title="SevMetadataOffset GUID table entry description"}

At this address when loaded, or at offset `ROM_end - (4GiB - Address)`, the `SevMetadata`,

| Type | Name |
| ---- | ---- |
| LE_UINT32 | Signature |
| LE_UINT32 | Length |
| LE_UINT32 | Version |
| LE_UINT32 | NumSections |
| SevMetadataSection[Sections] | Sections |
{: title="SevMetadata type description" }

The `Signature` value should be `'A', 'S', 'E', 'V'` or "VESA" in big-endian order: `0x56455341`.
Where `SevMetadataSection` is

| Type | Name |
| ---- | ---- |
| LE_UINT32 | Address |
| LE_UINT32 | Length |
| LE_UINT32 | Kind |
{: title="SevMetadataSection type description"}

A section references some slice of guest physical memory that has a certain purpose as labeled by `Kind`:

| Value | Name | PAGE_TYPE |
| ----- | ---- | --------- |
| 1 | OVMF_SECTION_TYPE_SNP_SEC_MEM | PAGE_TYPE_UNMEASURED |
| 2 | OVMF_SECTION_TYPE_SNP_SECRETS | PAGE_TYPE_SECRETS |
| 3 | OVMF_SECTION_TYPE_CPUID | PAGE_TYPE_CPUID |
| 4 | OVMF_SECTION_TYPE_SNP_SVSM_CAA | PAGE_TYPE_ZERO |
| 16 | OVMF_SECTION_TYPE_KERNEL_HASHES | PAGE_TYPE_NORMAL |
{: title="OVMF section kind to SEV-SNP page type mapping"}

The memory allocated to the initial UEFI boot phase, `SEC`, is unmeasured but must be marked for encryption without needing the `GHCB` or `MSR` protocol.
The `SEC_MEM` sections contain the initial `GHCB` pages, page tables, and temporary memory for stack and heap.
The secrets section is memory allocated specifically for holding secrets that the AMD-SP populates at launch.
The cpuid section is memory allocated to the CPUID source of truth, which shouldn't be measured for portability and host security, but should be verified by AMD-SP for validity.
The SVSM calling area address section is to enable the firmware to communicate with a secure VM services module running at VMPL0.
The kernel hashes section is populated with expected measurements when boot advances to load Linux directly and must fail if the disk contents' digests disagree with the measured hashes.

The producer of the OVMF binary may therefore decide to sign a verbose representation or a compact representation.
A verbose representation would have hundreds of updates given that every 4KiB page must be represented.
For an initial example, consider the 2MiB OVMF ROM's 512 4KiB updates as the baseline, and the metadata as individual measurements afterwards.

~~~ cbor-diag
{::include cddl/examples/ovmf-verbose.diag}
~~~

In this example the SEV-ES reset vector is located at `0x80b004`.
The AP RIP is the lower word and the CS_BASE is the upper word.
The first unmeasured section is for the SEC stage page tables up to GHCB at address `0x800000`, which has 9 pages accounted for in sequence.
The second unmeasured section is for the GHCB page up to secrets at address `0x80A000`, which has 3 pages accounted for in sequence.
The secrets page is at address `0x80D000`.
The CPUID page is at address `rx80E000`.
The svsm calling area page address is `0x80F000`.
The launch secrets and kernel hashes are at address `0x810000` and fit in 1 page.
The location of the final unmeasured pages are for the APIC page tables and PEI temporary memory.
The final section after the svsm calling area and kernel hashes up to the PEI firmware volume base, so `0x811000` up to `0x820000` for another 15 pages.

A more compact representation can take advantage of the fact that several of the first update commands are driven entirely by the firmware.
The firmware author may then decide to reorder the section processing to ensure the kernel hashes are last, as there is no requirement for sequential GPAs.
The baseline contains the initial ROM plus all the sections that don't have a dependency on external measured information.
Thanks to the section reordering, only the `SEV_KERNEL_HASHES` need to be called out in the signed configuration.

~~~ cbor-diag
{::include cddl/examples/ovmf-compact.diag}
~~~

#### Kernel data

The OVMF image may be provided by a different vendor than the OS disk image.
The user of the VM platform may not have direct access to reference values ahead of time to countersign their combination.
The kernel hashes become an input to the control plane that are then fed to the construction of the VM launch.
The provider of the OS disk image then is responsible for signing the reference values for kernel hashes.
The order in which kernel hashes are loaded, and at which address is irrelevant provided the attestation policy requires some signed value in the end, so the signer does not provide either the `gpa` or `seq-no` values.

~~~ cbor-diag
{::include cddl/examples/kernel-hashes.diag}
~~~

The digest is of a Qemu data structure that contains different digests of content from the command line.

# IANA Considerations

## New CBOR Tags

IANA is requested to allocate the following tags in the "CBOR Tags" registry {{!IANA.cbor-tags}}.
The choice of the CoRIM-earmarked value is intentional.

| Tag   | Data Item | Semantics                                                                             | Reference |
| ---   | --------- | ---------                                                                             | --------- |
| 563   | `map`     | Keys are always int, values are opaque bytes, see {{sec-id-tag}}                      | {{&SELF}} |
| 32780 | `bytes`   | A digest of an AMD public key format that compares with other keys {{sec-key-digest}} | {{&SELF}} |
| 32781 | `map`   | A map of virtual machine vCPU registers (VMSA) to initial values {{vmsa-evidence}} | {{&SELF}} |
| 32782 | `array`   | A record of a single VMSA and a count of how many times it repeats {{vmsa-evidence}} | {{&SELF}} |
{: #cbor-tags title="Added CBOR tags"}
