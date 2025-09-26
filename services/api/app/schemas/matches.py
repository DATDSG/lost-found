from app.schemas.common import ORMBase

class MatchPublic(ORMBase):
    id: int
    lost_item_id: int
    found_item_id: int
    score: float