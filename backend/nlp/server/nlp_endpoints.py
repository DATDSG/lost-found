# NLP Service API Endpoints
from fastapi import HTTPException
from .main import app, _load_embedding_model, _load_ner_model, _load_translator, _detect_language, _dummy_embed, settings
import numpy as np

@app.post("/embed")
async def embed_texts(request: EmbedRequest):
    """Generate E5-multilingual embeddings"""
    try:
        texts = [_preprocess_text(t) for t in request.texts]
        languages = [_detect_language(t) for t in texts]
        
        # Add E5 prefixes
        prefixed_texts = [f"{request.kind}: {t}" for t in texts]
        
        if settings.NLP_MODE == "real":
            model = _load_embedding_model()
            if model:
                vectors = model.encode(prefixed_texts, normalize_embeddings=request.normalize or settings.NORMALIZE_EMBEDDINGS)
                embeddings = np.asarray(vectors, dtype=np.float32)
            else:
                embeddings = _dummy_embed(prefixed_texts)
        else:
            embeddings = _dummy_embed(prefixed_texts)
            
        return EmbedResponse(
            vectors=embeddings.tolist(),
            dim=int(embeddings.shape[1]),
            mode=settings.NLP_MODE,
            model_name=settings.EMBEDDING_MODEL,
            languages_detected=languages
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ner")
async def extract_entities(request: NERRequest):
    """Extract named entities and attributes"""
    try:
        model = _load_ner_model()
        all_entities = []
        all_attributes = []
        languages = []
        
        for text in request.texts:
            lang = _detect_language(text)
            languages.append(lang)
            
            if model:
                doc = model(text)
                entities = [
                    Entity(
                        text=ent.text,
                        label=ent.label_,
                        start=ent.start_char,
                        end=ent.end_char,
                        confidence=float(ent._.get("confidence", 0.8))
                    ) for ent in doc.ents
                ]
            else:
                entities = []
            
            all_entities.append(entities)
            
            # Extract item attributes
            if request.extract_attributes:
                attributes = _extract_item_attributes(text, entities)
                all_attributes.append(attributes)
            else:
                all_attributes.append({})
                
        return NERResponse(
            entities=all_entities,
            attributes=all_attributes,
            languages_detected=languages
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def _extract_item_attributes(text: str, entities: list) -> dict:
    """Extract item-specific attributes"""
    attributes = {}
    text_lower = text.lower()
    
    # Color extraction
    colors = ["black", "white", "red", "blue", "green", "yellow", "brown", "gray", "pink", "purple"]
    for color in colors:
        if color in text_lower:
            attributes["color"] = color
            break
    
    # Brand extraction from entities
    for entity in entities:
        if entity.label in ["ORG", "PRODUCT"]:
            attributes["brand"] = entity.text
            break
    
    return attributes
