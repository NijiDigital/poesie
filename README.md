# POEditor

Ce repository contient l'ensemble des **scripts**, **outils**, pages de **documentation** nécessaires à la **génération** des strings (wordings) `iOS` et `Android` :

* `POEditor` ~> Le générateur de strings (wordings) **iOS** et **Android**

> Cet outil permet de générer à partir des fichiers de strings exportés depuis `POEditor` les fichiers de strings **iOS** (`Localizable.strings` / `Localizable.stringsdict`) et **Android** (`strings.xml`), en opérant une opération de nettoyage des strings spécifiques à une des plateformes.

---

## Installation

L'outil peut être invoqué en direct après ajout au `PATH` de votre environnement du répertoire `bin` contenu dans `POEditor`, ou en précisant le chemin complet vers le script Ruby exécutable `poeditor` contenu dans ce même répertoire `bin`.

Plusieurs options de ligne de commande peuvent être utilisées lors de l'invocation de cet outil :

```
➜ ✗ poeditor -h
Usage: poeditor [options]
    -t, --token API_TOKEN            Specify your POEditor API token
    -p, --project PROJECT_ID    Specify your POEditor project identifier
    -l, --lang LANGUAGE         Specify your POEditor project language
    -i, --ios PATH              Specify iOS Localizable.strings file path
    -a, --android PATH          Specify Android strings.xml file path
    -c, --context PATH          Specify your context.json file
    -h, --help                  Show this message
    -v, --version               Show version
```

## Processus d'utilisation

Vous avez besoin d’un string **qui se traduit !!!** dans votre projet **iOS** et **Android** ?

### 1) Existe-t-il déjà ?

1) Regarder si la valeur (la traduction) n’existe pas déjà dans votre projet sous [POEditor](https://poeditor.com).

* Si oui, utilisez la clé correspondante dans vos fichiers `Localizable.strings`,  `strings.xml`, `.storyboard`, `.xib` ou fichier source, et **c’est fini !!!**.
* Si non, il faut ajouter un nouveau terme dans l'outil `POEditor`.

> **NB:** Il est important de ne pas dupliquer des traductions similaires (avec des clés différentes) pour éviter de devoir traduire plusieurs fois les mêmes termes, et d'augmenter le quota **POEditor** du compte Niji de façon non justifiée.

### 2) Ajout dans `POEditor`

Se connecter sur [POEditor](https://poeditor.com) avec le compte suivant identifié à cette [page](http://redmine-niji/redmine/projects/niji-outils-transverses/wiki/Poeditor_compte). Ce compte est à utiliser pour tous les projets :

* Login : **poeditor@niji.fr**
* Password : **EDp12L!?**

> **NB:** Seul ce compte permet d’ajouter des nouveaux termes

### 3) Ajouter le nouveau terme

* Utilisez le `_` comme séparateur
* Trouver un nom de clé **cohérent** avec les clés existantes

**Exemples :**
>
> Si vous ajoutez une clé qui concerne le ou les magasin(s), nommez là
> `shop_xxx_xxx`.
>
> Si vous ajoutez un terme assez générique synonyme d'action comme **Appuyer**, nommez la clé `action_push` par exemple.

* Suffixez par `_ios` ou `_android` toute clé qui n'est utilisée que pour une des 2 plateformes mais pas l'autre
* Pour les clés qui contiennent un **format**: utilisez `%s` (ou `%n$s` où `n` est un chiffre) pour les chaînes de caractère, et non `%@`. Sur iOS, le `%s` (resp. `%1$s`) sera converti en `%@` (resp. `%1$@`) par le script. Cela permet d'utiliser la même chaîne avec format pour Android et iOS.

> Rappel: la syntaxe `%n$s` permet d'indiquer l'index du paramètre à utiliser. Cela permet ainsi d'inverser l'ordre des paramètres dans la traduction (`%1$s's %2$d phones` en anglais donnera "John's 3 phones" alors que `Les %2$d téléphones de %1$s` en français donnera "Les 3 téléphones de John"). S'il n'est pas précisé (juste `%s`), les paramètres sont pris dans l'ordre dans lequel ils sont passés. _(Il est cependant conseillé d'utiliser `%n$s` et d'indiquer la position même s'il se trouve que les paramètres qui seront passés lors de la traduction sont déjà dans l'ordre, pour être explicite)_

**Exemples :**

```
// iOS - Localizable.strings
"credentials_message_confirm_ios" = "Vous allez recevoir un e-mail à l'adresse %1$s vous invitant à définir un nouveau code secret.\nMerci de consulter vos e-mails.";
"trash_restore_documents" = "Confirmez-vous la restauration de cet élément ?";
```

```
// iOS - Localizable.stringsdict
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
    <dict>
        <key>trash_restore_documents_android</key>
        <dict>
            <key>NSStringLocalizedFormatKey</key>
            <string>%#@format@</string>
            <key>format</key>
            <dict>
                <key>NSStringFormatSpecTypeKey</key>
                <string>NSStringPluralRuleType</string>
                <key>NSStringFormatValueTypeKey</key>
                <string>d</string>
                <key>one</key>
                <string>Confirmez-vous la restauration de cet élément ?</string>
                <key>other</key>
                <string>Confirmez-vous la restauration de ces %d éléments ?</string>
            </dict>
        </dict>
    </dict>
</plist>
```

// Android
<string name="documents_add_date_android">"Le %1$s à %2$s"</string>
<string name="home_upload_again_confirmation_document_android">"Votre document %1$s n'a pas pu être ajouté.\nVoulez-vous poursuivre l'ajout de ce document ?"</string>
<plurals name="trash_restore_documents">
    <item quantity="one">"Confirmez-vous la restauration de cet élément ?"</item>
    <item quantity="other">"Confirmez-vous la restauration de ces %d éléments ?"</item>
</plurals>
```

> **NB:** Il n'est pas nécessaire d'échapper sur Android les caractères spéciaux type `'`.

### 4) Exécution du script

Exécuter le script Ruby `poeditor` qui **génère** les fichiers de strings dans le projet **Xcode** et **Android Studio**.

**Exemples** :

```
➜ ✗ poeditor -p 32644 -l fr -a /Users/KiKi/Documents/Dev/GitLab/LaPoste/Pass-Android/app/src/main/res/values/strings.xml
```

```
➜ ✗ poeditor -t c47665dfb4c65882a0f1059540e2524a -p 45344 -l fr -i /Users/KiKi/Documents/Dev/GitLab/Monoprix/Monoprix-iOS/Resources/Localizable.strings
```

> **NB:** Les identifiants de vos projets respectifs sont disponibles à l'adresse suivante [POEditor](https://poeditor.com/account/api).

### 4) Utilisation de --context

Exécuter le script Ruby `poeditor` avec l'option `--context FILE`, qui **génère** un fichier .json contenant toutes les entités comprenant un élément context.

**Exemples** :

```
➜ ✗ poeditor --token "..." --project "..." --lang fr --ios .../localizable.strings --context .../context.json
```

Vous pouvez ensuite utiliser le résultat du fichier `context.json` obtenu comme vous le souhaitez, voici par exemple quelques idées :

* Intégrer le fichier `context.json` dans votre projet Xcode, et utilise `JSONSerialization` pour le parser dans votre code Swift et vous en servir dans votre code
* Utiliser un script ruby simple pour générer du code Swift d'après ce fichier JSON. Un exemple est disponible dans `exemples/gen-context.rb`, et ce script est invoqué dans l'exemple `exemples/poeditor+context.sh`.
* Utiliser un outil de templating comme [Liquid](https://github.com/Shopify/liquid). Un exemple est disponible dans `exemples/gen-context-with-liquid.rb`
