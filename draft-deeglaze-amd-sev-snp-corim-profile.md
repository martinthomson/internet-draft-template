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

## AMD SEV-SNP CoRIM Profile

AMD SEV-SNP launch endorsements are carried in one or more CoMIDs inside a CoRIM.

The profile attribute in the CoRIM MUST be present and MUST have a single entry set to the uri http://amd.com/please-permalink-me as shown in {#figure-profile}.


{% figure caption:"SEV-SNP attestation profile version 1, CoRIM profile" %}

~~~ cbor-diag
/ corim-map / {
  / corim.profile / 3: [
    32("http://amd.com/please-permalink-me")
  ]
  / ... /
}
~~~
{% endfigure %}

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
{::include cddl/sevsnphost-launch-tcb-ext.cddl}
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
The `authorized-by` key SHALL be set to a representation of the V(CL)EK key that signed the `ATTESTATION_REPORT`, or a key along the certificate path to a self-signed root, i.e., the ASK, ASVK, or ARK for the product line.
The `measurement-values-map` is set as described in the following section.

#### `measurement-values-map`

The function `is-set(x, b)` represents whether the bit at position `b` is set in the number `x`.

*  The `digests: 2` codepoint SHALL be set to either `[ / digest / { alg: 7 val: MEASUREMENT } ]` or `[ / digest / { alg: "sha-384" val: MEASUREMENT } ]` as assigned in [named-info].

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
This section documents an event log format the Virtual Machine Monitor may construct at launch time and provide in the data pages of an extended guest request, as documented in [GHCB].

The content media type shall be `application/vnd.amd.sevsnp.launch-updates+cbor`.

# IANA Considerations

## New CBOR Tags

IANA is requested to allocate the following tags in the "CBOR Tags" registry {{!IANA.cbor-tags}}.
The choice of the CoRIM-earmarked value is intentional.

| Tag   | Data Item | Semantics                                                                             | Reference |
| ---   | --------- | ---------                                                                             | --------- |
| 563   | `map`     | Keys are always int, values are opaque bytes, see {{sec-id-tag}}                      | {{&SELF}} |
| 32780 | `bytes`   | A digest of an AMD public key format that compares with other keys {{sec-key-digest}} | {{&SELF}} |
