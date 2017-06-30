function Set-ArrowCharacters() {
    $arrowDefs = (Get-Content -Path "$Env:USERPROFILE\.git-psradar" -Encoding Unicode).Split("`n");
    $arrows.upArrow = $arrowDefs[0];$arrows.downArrow = $arrowDefs[1];$arrows.rightArrow = $arrowDefs[2];$arrows.leftArrow = $arrowDefs[3]; $arrows.leftRightArrow = $arrowDefs[4];
}