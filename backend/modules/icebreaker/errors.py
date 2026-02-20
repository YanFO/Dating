class IcebreakerError(Exception):
    pass


class ImageAnalysisFailed(IcebreakerError):
    pass


class InvalidInputError(IcebreakerError):
    pass
