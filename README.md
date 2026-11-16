# Gestion de la virtualisation Windows (Hyper-V)

Deux scripts PowerShell pour **activer ou désactiver des fonctionnalités de virtualisation Windows** et les protections de sécurité qui utilisent l'hyperviseur.

| Script | Rôle |
| --- | --- |
| `Activation_Hyper-V.ps1` | Configure l'activation de la virtualisation et des protections associées. |
| `Désactivation_Hyper-V.ps1` | Configure leur désactivation et empêche le lancement automatique de l'hyperviseur. |

> [!IMPORTANT]
> Ces scripts ne se limitent **pas** à Hyper-V : ils modifient aussi WSL, Windows Sandbox, VBS, HVCI et Credential Guard. **L'activation de Credential Guard avec verrouillage UEFI peut compliquer sa désactivation.** Lisez les [précautions](#précautions-et-limites) avant toute exécution.

## Fonctionnalités modifiées

Les deux scripts activent ou désactivent les cinq composants Windows suivants :

| Fonctionnalité | Identifiant Windows | Utilité |
| --- | --- | --- |
| Hyper-V | `Microsoft-Hyper-V-All` | Exécution de machines virtuelles Hyper-V. |
| Plateforme de machine virtuelle | `VirtualMachinePlatform` | Composants utilisés notamment par WSL 2. |
| Plateforme de l'hyperviseur Windows | `HypervisorPlatform` | Interface de virtualisation pour certains logiciels tiers. |
| Windows Sandbox | `Containers-DisposableClientVM` | Environnement Windows temporaire et isolé. |
| Sous-système Windows pour Linux | `Microsoft-Windows-Subsystem-Linux` | Fonctionnalité Windows nécessaire à WSL. |

Ils modifient également les paramètres suivants :

| Paramètre | Activation | Désactivation |
| --- | --- | --- |
| Intégrité de la mémoire (**HVCI**) | `Enabled = 1` | `Enabled = 0` |
| Sécurité basée sur la virtualisation (**VBS**) | `EnableVirtualizationBasedSecurity = 1` | `= 0` |
| **Credential Guard** | `LsaCfgFlags = 1` et `CredentialGuard\Enabled = 1` | Valeurs à `0` |
| Démarrage de l'hyperviseur (`bcdedit`) | `hypervisorlaunchtype auto` | `hypervisorlaunchtype off` |

Les paramètres HVCI, VBS et Credential Guard sont écrits dans le Registre Windows (`HKLM:\SYSTEM\CurrentControlSet\Control\`). Les fonctionnalités Windows sont gérées avec `Enable-WindowsOptionalFeature` ou `Disable-WindowsOptionalFeature`.

> **À savoir :** ces scripts ne créent ni machine virtuelle ni distribution Linux. Ils ne changent pas non plus les options de virtualisation matérielle du BIOS/UEFI (Intel VT-x / AMD-V).

## Prérequis

- **Windows 10 ou Windows 11**, dans une édition compatible avec les fonctionnalités souhaitées (Hyper-V complet et Windows Sandbox ne sont pas disponibles sur toutes les éditions).
- Un processeur et un BIOS/UEFI compatibles avec la virtualisation matérielle.
- **Windows PowerShell ouvert en administrateur** (`#Requires -RunAsAdministrator` est présent dans les deux scripts).
- La possibilité de **redémarrer** le PC pour appliquer les changements.

## Utilisation

### 1. Télécharger et ouvrir le dossier

Téléchargez le dépôt (**Code → Download ZIP**), extrayez-le puis ouvrez **Windows PowerShell en tant qu'administrateur** dans le dossier contenant les scripts :

```powershell
cd "C:\Chemin\Vers\Le\Dossier"
```

### 2. Autoriser l'exécution des scripts (si nécessaire)

Si votre politique PowerShell bloque l'exécution des scripts, vous pouvez utiliser :

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Cette politique autorise les scripts locaux non signés, mais exige en principe une signature pour ceux identifiés comme téléchargés depuis Internet (sauf déblocage explicite). Elle ne concerne que **votre compte utilisateur** et ne fournit pas de droits administrateur. Une politique d'entreprise peut rester prioritaire.

Pour supprimer ce réglage propre à votre compte et revenir à la politique définie par les autres niveaux :

```powershell
Set-ExecutionPolicy Undefined -Scope CurrentUser
```

### 3. Lancer le script souhaité

**Activer** les fonctionnalités et protections :

```powershell
.\Activation_Hyper-V.ps1
```

**Désactiver** les fonctionnalités et protections :

```powershell
.\Désactivation_Hyper-V.ps1
```

### 4. Redémarrer

À la fin, le script demande `Redemarrer maintenant ? (O/N)` :

- `O` : redémarrage immédiat via `Restart-Computer -Force` ; **enregistrez vos fichiers avant de répondre**.
- `N` : pas de redémarrage immédiat ; effectuez-le manuellement ensuite.

## Vérifier après le redémarrage

Consulter l'état d'Hyper-V :

```powershell
Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All"
```

Vérifier la configuration de lancement de l'hyperviseur :

```powershell
bcdedit /enum "{current}"
```

Contrôler l'état réel de VBS et des services de sécurité :

```powershell
Get-CimInstance -Namespace "root\Microsoft\Windows\DeviceGuard" -ClassName Win32_DeviceGuard |
    Select-Object VirtualizationBasedSecurityStatus, SecurityServicesConfigured, SecurityServicesRunning
```

Vous pouvez aussi utiliser `msinfo32`. **Une valeur écrite dans le Registre ne garantit pas qu'une protection soit effectivement active ou inactive.**

## Précautions et limites

- **Credential Guard :** l'activation définit `LsaCfgFlags = 1`, c'est-à-dire une configuration **avec verrouillage UEFI**. Si celui-ci est appliqué, remettre la valeur à `0` peut ne pas suffire : une [procédure Microsoft spécifique](https://learn.microsoft.com/fr-fr/windows/security/identity-protection/credential-guard/configure) peut être nécessaire.
- **Sécurité :** la désactivation de VBS, HVCI et Credential Guard peut **réduire les protections de Windows**. N'utilisez pas le script de désactivation si vous souhaitez seulement arrêter Hyper-V tout en conservant ces protections.
- **Compatibilité :** désactiver WSL, `VirtualMachinePlatform` ou l'hyperviseur peut empêcher WSL 2, certaines machines virtuelles ou Docker Desktop de fonctionner.
- **Résultat non garanti :** certaines fonctionnalités peuvent manquer selon l'édition de Windows ; les erreurs non bloquantes de gestion des fonctionnalités sont masquées par `-ErrorAction SilentlyContinue`. Vérifiez l'état après redémarrage.
- **Pas de sauvegarde automatique :** les scripts ne mémorisent pas la configuration initiale et ne garantissent pas un retour à l'identique. Ils ne contiennent toutefois aucune commande visant à supprimer directement des VM ou distributions Linux.

> [!WARNING]
> Testez de préférence ces scripts sur une machine non critique. Évitez de les lancer sur un poste professionnel soumis à des stratégies de sécurité sans l'accord de l'administrateur.

## Documentation Microsoft

- [Présentation d'Hyper-V sur Windows](https://learn.microsoft.com/fr-fr/virtualization/hyper-v-on-windows/about/)
- [Configurer Credential Guard](https://learn.microsoft.com/fr-fr/windows/security/identity-protection/credential-guard/configure)
- [Windows Sandbox](https://learn.microsoft.com/fr-fr/windows/security/application-security/application-isolation/windows-sandbox/)

## Auteur

**Karim GASMI** — Étudiant en Systèmes, Réseaux & Cloud Computing à l'ESGI.
