"""Reference data API endpoints."""

from fastapi import APIRouter

from pydantic import BaseModel, Field
from app.schemas.common import BaseResponse

router = APIRouter()

# Lista dos 213 bairros do Rio de Janeiro (oficial)
# Fonte: Prefeitura do Rio de Janeiro
RIO_NEIGHBORHOODS = [
    "abolição",
    "acari",
    "água santa",
    "alto da boa vista",
    "anchieta",
    "andaraí",
    "anil",
    "bancários",
    "bangu",
    "barra da tijuca",
    "barra de guaratiba",
    "barros filho",
    "benfica",
    "bento ribeiro",
    "bonsucesso",
    "botafogo",
    "brás de pina",
    "cachambi",
    "cacuia",
    "caju",
    "camorim",
    "campinho",
    "campo dos afonsos",
    "campo grande",
    "cascadura",
    "catete",
    "catumbi",
    "cavalcanti",
    "centro",
    "cidade de deus",
    "cidade nova",
    "cidade universitária",
    "cocotá",
    "coelho neto",
    "colégio",
    "complexo do alemão",
    "copacabana",
    "cordovil",
    "cosme velho",
    "cosmos",
    "costa barros",
    "curicica",
    "del castilho",
    "deodoro",
    "encantado",
    "engenheiro leal",
    "engenho da rainha",
    "engenho de dentro",
    "engenho novo",
    "estácio",
    "farroupilha",
    "flamengo",
    "freguesia",
    "frequesia (ilha)",
    "galeão",
    "gamboa",
    "gardênia azul",
    "gávea",
    "glória",
    "grajaú",
    "grumari",
    "guadalupe",
    "guaratiba",
    "higienópolis",
    "honório gurgel",
    "humaitá",
    "ilhamarabá",
    "inhaúma",
    "inhoaíba",
    "ipanema",
    "irajá",
    "itanhangá",
    "jacaré",
    "jacarepaguá",
    "jacarezinho",
    "jardim américa",
    "jardim botânico",
    "jardim carioca",
    "jardim guanabara",
    "jardim sulacap",
    "joá",
    "lagoa",
    "laranjeiras",
    "leblon",
    "leme",
    "lins de vasconcelos",
    "madureira",
    "magalhães bastos",
    "mangueira",
    "manguinhos",
    "maracanã",
    "maré",
    "marechal hermes",
    "maria da graça",
    "méier",
    "moneró",
    "olaria",
    "oswaldo cruz",
    "paciência",
    "padre miguel",
    "paquetá",
    "parada de lucas",
    "parque anchieta",
    "parque colúmbia",
    "pavuna",
    "pechincha",
    "pedra de guaratiba",
    "penha",
    "penha circular",
    "piedade",
    "pilares",
    "pitangueiras",
    "portuguesa",
    "praça da bandeira",
    "praça seca",
    "praia da bandeira",
    "quintino bocaiúva",
    "ramos",
    "realengo",
    "recreio dos bandeirantes",
    "riachuelo",
    "ribeira",
    "ricardo de albuquerque",
    "rio comprido",
    "rocha",
    "rocha miranda",
    "rocinha",
    "sampaio",
    "santa cruz",
    "santa teresa",
    "santíssimo",
    "santo cristo",
    "são conrado",
    "são cristóvão",
    "são francisco xavier",
    "sapê",
    "saúde",
    "senador camará",
    "senador vasconcelos",
    "sepetiba",
    "tanque",
    "taquara",
    "tauá",
    "tijuca",
    "todos os santos",
    "tomás coelho",
    "turiaçu",
    "urca",
    "vargem grande",
    "vargem pequena",
    "vasco da gama",
    "vicente de carvalho",
    "vidigal",
    "vigário geral",
    "vila da penha",
    "vila isabel",
    "vila kosmos",
    "vila militar",
    "vila valqueire",
    "vista alegre",
    "zumbi",
]


class Neighborhood(BaseModel):
    """Neighborhood reference data."""

    name: str = Field(..., description="Neighborhood name (lowercase)")
    display_name: str = Field(..., description="Display name (title case)")


class NeighborhoodsResponse(BaseResponse):
    """Response for neighborhoods list."""

    data: list[Neighborhood] = Field(
        default_factory=list, description="List of neighborhoods"
    )
    count: int = Field(default=0, description="Total count")


@router.get(
    "/neighborhoods",
    response_model=NeighborhoodsResponse,
    summary="List Neighborhoods",
    description="Get list of all Rio de Janeiro neighborhoods.",
)
async def list_neighborhoods() -> NeighborhoodsResponse:
    """
    Get list of all Rio de Janeiro neighborhoods.

    Returns a list of 213 official neighborhoods from Rio de Janeiro.
    Names are in lowercase for consistency with subscription matching.

    Returns:
        List of neighborhoods with name and display_name
    """
    neighborhoods = [
        Neighborhood(
            name=name,
            display_name=name.title(),
        )
        for name in sorted(RIO_NEIGHBORHOODS)
    ]

    return NeighborhoodsResponse(
        data=neighborhoods,
        count=len(neighborhoods),
    )
