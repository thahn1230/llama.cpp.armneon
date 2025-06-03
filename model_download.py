from transformers import AutoModel, AutoTokenizer

model_name = ""

# 모델과 토크나이저 다운로드
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModel.from_pretrained(model_name)

# 원하는 경로로 저장
save_directory = "./my_model_dir"
tokenizer.save_pretrained(save_directory)
model.save_pretrained(save_directory)

print(f"모델과 토크나이저를 {save_directory}에 저장했습니다!")
